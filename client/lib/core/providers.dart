import 'package:shared_preferences/shared_preferences.dart';

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:casama_sdk/casama_sdk.dart';

import 'backend.dart';
import 'local_cache.dart';
import 'number_format.dart';

/// The backend; overridden in main() and in tests.
final backendProvider = Provider<Backend>((ref) => throw UnimplementedError('backendProvider must be overridden'));

/// Sign-ins the server turns on beyond email, Google and Apple (SSO, passkeys). Hidden when the
/// server can't say.
final authMethodsProvider = FutureProvider<AuthMethods>((ref) async {
  try {
    return await ref.watch(backendProvider).authMethods();
  } catch (_) {
    return const AuthMethods();
  }
});

/// After a reset link or code, until a new password is chosen or skipped.
final newPasswordNeededProvider = StreamProvider<bool>((ref) async* {
  final backend = ref.watch(backendProvider);
  yield backend.newPasswordNeeded;
  yield* backend.newPasswordNeededChanges;
});

/// Signed in with a password or link but the two-step code (aal2) not entered yet. Re-read on
/// every auth change; the two-step screen also invalidates it once the code passes.
final twoStepCodeNeededProvider = Provider<bool>((ref) {
  ref.watch(signedInProvider);
  return ref.watch(backendProvider).twoStepCodeNeeded;
});

/// Signed in all the way: the two-step code and any new password after a reset are done. The
/// one-time pages over the app (the name step, turning on notifications) wait for this.
final signInFinishedProvider = Provider<bool>((ref) {
  if (ref.watch(signedInProvider).value != true) return false;
  return !ref.watch(twoStepCodeNeededProvider) && ref.watch(newPasswordNeededProvider).value != true;
});

/// Signed-in state, updated from the backend's auth stream.
final signedInProvider = StreamProvider<bool>((ref) async* {
  final backend = ref.watch(backendProvider);
  yield backend.isSignedIn;
  yield* backend.signedInChanges;
});

/// Workspaces. At launch they come from the offline cache at once and the server's replace them;
/// offline, the saved ones stay (D-158). After a change (an invalidate: a workspace created, joined
/// or left) the server's are awaited, so a stale list never shows.
class OrganizationsNotifier extends AsyncNotifier<List<OrganizationWithRole>> {
  var _launched = false;
  var _generation = 0;

  @override
  Future<List<OrganizationWithRole>> build() async {
    final signedIn = ref.watch(signedInProvider).value ?? false;
    if (!signedIn) return const [];
    final backend = ref.watch(backendProvider);
    final cache = ref.watch(localCacheProvider);
    // By user: one cache serves every server this device has signed in to.
    final user = backend.userId;
    final key = user == null ? null : 'orgs:$user';
    final gen = ++_generation;
    final fresh = backend.organizations().then((v) {
      if (key != null) unawaited(cacheWrite(cache, key, [for (final o in v) o.toJson()]));
      return v;
    });
    // Handled here too, so an offline failure doesn't count as unhandled while the cache is read.
    fresh.ignore();
    Future<List<OrganizationWithRole>?> saved() async {
      if (key == null) return null;
      final cached = await cacheRead(cache, key);
      if (cached is! List || cached.isEmpty) return null;
      try {
        return [for (final j in cached) OrganizationWithRole.fromJson(Map<String, dynamic>.from(j as Map))];
      } catch (_) {
        return null;
      }
    }

    if (!_launched) {
      _launched = true;
      final cached = await saved();
      if (cached != null) {
        unawaited(
          fresh
              .then((v) {
                if (ref.mounted && gen == _generation) state = AsyncData(v);
              })
              .catchError((_) {}),
        );
        return cached;
      }
    }
    try {
      return await fresh;
    } catch (_) {
      final cached = await saved();
      if (cached != null) return cached;
      rethrow;
    }
  }
}

final organizationsProvider = AsyncNotifierProvider<OrganizationsNotifier, List<OrganizationWithRole>>(OrganizationsNotifier.new);

/// The selected workspace id (defaults to the first one), remembered on this device (D-099).
class SelectedOrg extends Notifier<String?> {
  static const _key = 'casama.selected_org';

  @override
  String? build() {
    SharedPreferences.getInstance()
        .then((p) {
          final saved = p.getString(_key);
          if (saved != null && state == null) state = saved;
        })
        .catchError((_) {});
    return null;
  }

  void select(String? id) {
    state = id;
    SharedPreferences.getInstance().then((p) => id == null ? p.remove(_key) : p.setString(_key, id)).catchError((_) => false);
  }
}

/// An invite opened before signing in; shown again right after (D-099, D-167). Kept on the device
/// so it survives the app restarting during sign-up (a confirmation email opened later).
class PendingJoinToken extends Notifier<String?> {
  static const _key = 'casama.pending_join';

  @override
  String? build() {
    SharedPreferences.getInstance()
        .then((p) {
          final saved = p.getString(_key);
          if (saved != null && state == null) state = saved;
        })
        .catchError((_) {});
    return null;
  }

  void set(String? token) {
    state = token;
    SharedPreferences.getInstance().then((p) => token == null ? p.remove(_key) : p.setString(_key, token)).catchError((_) => false);
  }
}

final pendingJoinTokenProvider = NotifierProvider<PendingJoinToken, String?>(PendingJoinToken.new);

final selectedOrgIdProvider = NotifierProvider<SelectedOrg, String?>(SelectedOrg.new);

final currentOrgProvider = Provider<OrganizationWithRole?>((ref) {
  final orgs = ref.watch(organizationsProvider).value ?? const [];
  if (orgs.isEmpty) return null;
  final id = ref.watch(selectedOrgIdProvider);
  return orgs.firstWhere((o) => o.id == id, orElse: () => orgs.first);
});

/// Bots, shown from the offline cache first and refreshed in the background (D-112).
class BotsNotifier extends AsyncNotifier<List<Bot>> {
  var _generation = 0;

  @override
  Future<List<Bot>> build() async {
    final org = ref.watch(currentOrgProvider);
    if (org == null) return const [];
    final backend = ref.watch(backendProvider);
    final cache = ref.watch(localCacheProvider);
    final key = 'bots:${org.id}';
    final gen = ++_generation;
    final fresh = backend.bots(org.id).then((v) {
      unawaited(cacheWrite(cache, key, [for (final b in v) b.toJson()]));
      return v;
    });
    // Handled here too, so an offline failure doesn't count as unhandled while the cache is read.
    fresh.ignore();
    final cached = await cacheRead(cache, key);
    if (cached is List && cached.isNotEmpty) {
      unawaited(
        fresh
            .then((v) {
              if (ref.mounted && gen == _generation) state = AsyncData(v);
            })
            .catchError((_) {}),
      );
      try {
        return [for (final j in cached) Bot.fromJson(Map<String, dynamic>.from(j as Map))];
      } catch (_) {}
    }
    return fresh;
  }
}

final botsProvider = AsyncNotifierProvider<BotsNotifier, List<Bot>>(BotsNotifier.new);

/// Sidebar folders (D-100).
final botFoldersProvider = FutureProvider<List<BotFolder>>((ref) async {
  final org = ref.watch(currentOrgProvider);
  if (org == null) return const [];
  return ref.watch(backendProvider).botFolders(org.id);
});

final archivedBotsProvider = FutureProvider<List<Bot>>((ref) async {
  final org = ref.watch(currentOrgProvider);
  if (org == null) return const [];
  return ref.watch(backendProvider).archivedBots(org.id);
});

final botProvider = Provider.family<Bot?, String>((ref, id) {
  final bots = ref.watch(botsProvider).value ?? const [];
  for (final b in bots) {
    if (b.id == id) return b;
  }
  return null;
});

final credentialsProvider = FutureProvider<List<Credential>>((ref) async {
  final org = ref.watch(currentOrgProvider);
  if (org == null) return const [];
  return ref.watch(backendProvider).credentials(org.id);
});

/// Models a key can use for the bot model picker (cached by the server for 10 minutes).
final modelOptionsProvider = FutureProvider.family<ModelOptionList, String>((ref, credentialId) => ref.watch(backendProvider).models(credentialId));

final usageTodayProvider = FutureProvider<UsageReport?>((ref) async {
  final org = ref.watch(currentOrgProvider);
  if (org == null) return null;
  return ref.watch(backendProvider).usage(org.id, period: 'day');
});

final usageMonthProvider = FutureProvider<UsageReport?>((ref) async {
  final org = ref.watch(currentOrgProvider);
  if (org == null) return null;
  return ref.watch(backendProvider).usage(org.id, period: 'month');
});

final computersProvider = FutureProvider<List<Computer>>((ref) async {
  final org = ref.watch(currentOrgProvider);
  if (org == null) return const [];
  return ref.watch(backendProvider).computers(org.id);
});

final conversationsProvider = FutureProvider.family<List<Conversation>, String>((ref, botId) => ref.watch(backendProvider).conversations(botId));

final memoriesProvider = FutureProvider.family<List<Memory>, String>((ref, botId) => ref.watch(backendProvider).memories(botId));

final skillsProvider = FutureProvider<List<SkillView>>((ref) async {
  final org = ref.watch(currentOrgProvider);
  if (org == null) return const [];
  return ref.watch(backendProvider).skills(org.id);
});

final runsProvider = FutureProvider.family<List<RunSummary>, String>((ref, botId) => ref.watch(backendProvider).runs(botId));

final runEventsProvider = FutureProvider.family<List<RunEventItem>, String>((ref, runId) => ref.watch(backendProvider).runEvents(runId));

// --- Phase 4: autonomy ------------------------------------------------------

final templatesProvider = FutureProvider<List<Template>>((ref) => ref.watch(backendProvider).templates());

final approvalsProvider = FutureProvider<List<Approval>>((ref) async {
  final org = ref.watch(currentOrgProvider);
  if (org == null) return const [];
  return ref.watch(backendProvider).approvals(org.id);
});

/// The notification inbox: loaded once, then kept live from the user's Realtime topic.
class NotificationsNotifier extends AsyncNotifier<List<NotificationView>> {
  @override
  Future<List<NotificationView>> build() async {
    final signedIn = ref.watch(signedInProvider).value ?? false;
    if (!signedIn) return const [];
    final backend = ref.watch(backendProvider);
    final sub = backend.watchNotifications().listen((n) {
      // A phone call ringing (D-135): shown as the ringing banner, not in the inbox.
      if (n.kind == 'call') {
        ref.invalidate(ringingCallsProvider);
        return;
      }
      final current = state.value ?? const <NotificationView>[];
      if (current.any((c) => c.id == n.id)) return;
      state = AsyncData([n, ...current]);
      if (n.kind == 'approval' || n.kind == 'approval_request') ref.invalidate(approvalsProvider);
      if (n.kind == 'takeover') ref.invalidate(takeoversProvider);
    });
    ref.onDispose(sub.cancel);
    return [
      for (final n in await backend.notifications())
        if (n.kind != 'call') n,
    ];
  }

  /// Marks one notification read (opened from the inbox or from a push).
  Future<void> markRead(String id) async {
    final current = state.value ?? const <NotificationView>[];
    final now = DateTime.now();
    state = AsyncData([
      for (final n in current) n.id == id ? n.read(now) : n,
    ]);
    await ref.read(backendProvider).markNotificationRead(id);
  }

  /// Marks read what a bot's chat already shows (its replies and results), once the chat is open.
  Future<void> markBotChatRead(String botId) async {
    final unread = [
      for (final n in state.value ?? const <NotificationView>[])
        if (n.readAt == null && !n.isRequest && n.botId == botId && (n.link?.startsWith('/bots/$botId/chat') ?? false)) n.id,
    ];
    for (final id in unread) {
      await markRead(id);
    }
  }

  Future<void> markAllRead() async {
    await ref.read(backendProvider).markNotificationsRead();
    final now = DateTime.now();
    state = AsyncData([
      for (final n in state.value ?? const <NotificationView>[]) n.read(now),
    ]);
  }
}

final notificationsProvider = AsyncNotifierProvider<NotificationsNotifier, List<NotificationView>>(NotificationsNotifier.new);

/// Phone calls ringing for this person now (D-135), refreshed when a `call` notification arrives.
final ringingCallsProvider = FutureProvider<List<PhoneCall>>((ref) async {
  final signedIn = ref.watch(signedInProvider).value ?? false;
  if (!signedIn) return const [];
  return ref.watch(backendProvider).ringingCalls();
});

/// Badge count for the inbox: pending approvals plus unread notifications (approval notices are not double counted).
final inboxBadgeProvider = Provider<int>((ref) {
  final approvals = (ref.watch(approvalsProvider).value?.length ?? 0) + (ref.watch(takeoversProvider).value?.length ?? 0);
  final unread = (ref.watch(notificationsProvider).value ?? const <NotificationView>[]).where((n) => n.readAt == null && !n.isRequest).length;
  return approvals + unread;
});

/// What waits for the person from one bot: its pending approvals and takeovers, and its unread
/// notifications (shown as a count next to the bot in the sidebar).
final botBadgeProvider = Provider.family<int, String>((ref, botId) {
  final approvals = (ref.watch(approvalsProvider).value ?? const <Approval>[]).where((a) => a.botId == botId).length;
  final takeovers = (ref.watch(takeoversProvider).value ?? const <TakeoverRequest>[]).where((t) => t.botId == botId).length;
  final unread = (ref.watch(notificationsProvider).value ?? const <NotificationView>[]).where((n) => n.readAt == null && !n.isRequest && n.botId == botId).length;
  return approvals + takeovers + unread;
});

final routinesProvider = FutureProvider.family<List<Routine>, String>((ref, botId) => ref.watch(backendProvider).routines(botId));

/// Built-in apps (D-089); cached for the session.
final appCatalogProvider = FutureProvider<AppCatalog>((ref) => ref.watch(backendProvider).appCatalog());

final integrationsProvider = FutureProvider<List<Integration>>((ref) async {
  final org = ref.watch(currentOrgProvider);
  if (org == null) return const [];
  return ref.watch(backendProvider).integrations(org.id);
});

final botIntegrationIdsProvider = FutureProvider.family<Set<String>, String>((ref, botId) => ref.watch(backendProvider).botIntegrationIds(botId));

final secretsProvider = FutureProvider<List<Secret>>((ref) async {
  final org = ref.watch(currentOrgProvider);
  if (org == null) return const [];
  return ref.watch(backendProvider).secrets(org.id);
});

final tasksProvider = FutureProvider<List<Task>>((ref) async {
  final org = ref.watch(currentOrgProvider);
  if (org == null) return const [];
  return ref.watch(backendProvider).tasks(org.id);
});

/// Open requests from bots for a person to take over a screen.
final takeoversProvider = FutureProvider<List<TakeoverRequest>>((ref) async {
  final org = ref.watch(currentOrgProvider);
  if (org == null) return const [];
  return ref.watch(backendProvider).takeovers(org.id);
});

/// Formats US dollars for cost meters in the person's locale: two decimals from a dollar up and
/// at zero, four below so small costs don't read as $0.00.
String formatUsd(num value, String locale) => value.humanizedCurrency(locale, 'USD', decimalDigits: value >= 1 || value == 0 ? 2 : 4);
