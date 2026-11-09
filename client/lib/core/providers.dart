import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kasama_sdk/kasama_sdk.dart';

import 'backend.dart';

/// The backend; overridden in main() and in tests.
final backendProvider = Provider<Backend>((ref) => throw UnimplementedError('backendProvider must be overridden'));

/// Signed-in state, updated from the backend's auth stream.
final signedInProvider = StreamProvider<bool>((ref) async* {
  final backend = ref.watch(backendProvider);
  yield backend.isSignedIn;
  yield* backend.signedInChanges;
});

final organizationsProvider = FutureProvider<List<OrganizationWithRole>>((ref) async {
  final signedIn = ref.watch(signedInProvider).value ?? false;
  if (!signedIn) return const [];
  return ref.watch(backendProvider).organizations();
});

/// The selected workspace id (defaults to the first one).
class SelectedOrg extends Notifier<String?> {
  @override
  String? build() => null;
  void select(String? id) => state = id;
}

final selectedOrgIdProvider = NotifierProvider<SelectedOrg, String?>(SelectedOrg.new);

final currentOrgProvider = Provider<OrganizationWithRole?>((ref) {
  final orgs = ref.watch(organizationsProvider).value ?? const [];
  if (orgs.isEmpty) return null;
  final id = ref.watch(selectedOrgIdProvider);
  return orgs.firstWhere((o) => o.id == id, orElse: () => orgs.first);
});

final botsProvider = FutureProvider<List<Bot>>((ref) async {
  final org = ref.watch(currentOrgProvider);
  if (org == null) return const [];
  return ref.watch(backendProvider).bots(org.id);
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
final modelOptionsProvider = FutureProvider.family<ModelOptionList, String>(
  (ref, credentialId) => ref.watch(backendProvider).models(credentialId),
);

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

final conversationsProvider = FutureProvider.family<List<Conversation>, String>(
  (ref, botId) => ref.watch(backendProvider).conversations(botId),
);

final memoriesProvider = FutureProvider.family<List<Memory>, String>(
  (ref, botId) => ref.watch(backendProvider).memories(botId),
);

final skillsProvider = FutureProvider<List<SkillView>>((ref) async {
  final org = ref.watch(currentOrgProvider);
  if (org == null) return const [];
  return ref.watch(backendProvider).skills(org.id);
});

final runsProvider = FutureProvider.family<List<RunSummary>, String>(
  (ref, botId) => ref.watch(backendProvider).runs(botId),
);

final runEventsProvider = FutureProvider.family<List<RunEventItem>, String>(
  (ref, runId) => ref.watch(backendProvider).runEvents(runId),
);

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
      final current = state.value ?? const <NotificationView>[];
      if (current.any((c) => c.id == n.id)) return;
      state = AsyncData([n, ...current]);
      if (n.kind == 'approval') ref.invalidate(approvalsProvider);
      if (n.kind == 'takeover') ref.invalidate(takeoversProvider);
    });
    ref.onDispose(sub.cancel);
    return backend.notifications();
  }

  Future<void> markAllRead() async {
    await ref.read(backendProvider).markNotificationsRead();
    final now = DateTime.now();
    state = AsyncData([
      for (final n in state.value ?? const <NotificationView>[])
        NotificationView(id: n.id, kind: n.kind, title: n.title, body: n.body, link: n.link, createdAt: n.createdAt, readAt: n.readAt ?? now),
    ]);
  }
}

final notificationsProvider = AsyncNotifierProvider<NotificationsNotifier, List<NotificationView>>(NotificationsNotifier.new);

/// Badge count for the inbox: pending approvals plus unread notifications (approval notices are not double counted).
final inboxBadgeProvider = Provider<int>((ref) {
  final approvals = (ref.watch(approvalsProvider).value?.length ?? 0) + (ref.watch(takeoversProvider).value?.length ?? 0);
  final unread = (ref.watch(notificationsProvider).value ?? const <NotificationView>[])
      .where((n) => n.readAt == null && n.kind != 'approval' && n.kind != 'takeover')
      .length;
  return approvals + unread;
});

final routinesProvider = FutureProvider.family<List<Routine>, String>(
  (ref, botId) => ref.watch(backendProvider).routines(botId),
);

final integrationsProvider = FutureProvider<List<Integration>>((ref) async {
  final org = ref.watch(currentOrgProvider);
  if (org == null) return const [];
  return ref.watch(backendProvider).integrations(org.id);
});

final botIntegrationIdsProvider = FutureProvider.family<Set<String>, String>(
  (ref, botId) => ref.watch(backendProvider).botIntegrationIds(botId),
);

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

/// Formats US dollars for cost meters.
String formatUsd(num value) {
  if (value >= 1) return '\$${value.toStringAsFixed(2)}';
  if (value == 0) return '\$0.00';
  return '\$${value.toStringAsFixed(4)}';
}
