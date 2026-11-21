import 'package:casama_sdk/casama_sdk.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/haptics.dart';
import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../ui/adaptive_modal.dart';
import '../../ui/app_card.dart';
import '../../ui/form_sheet.dart';
import '../../ui/page.dart';
import 'app_browser_ask.dart';
import 'app_browser_channel.dart';
import 'app_browser_controller.dart';
import 'app_browser_flag.dart';
import 'app_browser_screen.dart';
import 'app_browser_service.dart';

/// Why the phone browser isn't available, in plain words (`GET /v1/app-browser`'s `reason`).
String appBrowserReasonText(AppLocalizations l10n, String? reason) =>
    switch (reason) {
      'not_a_tester' => l10n.appBrowserReasonNotTester,
      'system_off' => l10n.appBrowserReasonSystemOff,
      'workspace_off' => l10n.appBrowserReasonWorkspaceOff,
      'unavailable' => l10n.appBrowserReasonUnavailable,
      'unsupported' => l10n.appBrowserReasonUnsupported,
      _ => l10n.appBrowserReasonOff,
    };

const _kinds = ['banking', 'health', 'passwords', 'government'];

final _supportProvider = FutureProvider.autoDispose<AppBrowserSupport>(
  (ref) => ref.read(appBrowserProvider.notifier).support(),
);
final _hasTokenProvider = FutureProvider.autoDispose.family<bool, String>(
  (ref, id) async =>
      await ref.read(appBrowserTokenStoreProvider).read(id) != null,
);

/// The row in Settings → Device connections (plan §4): only in a build with the phone browser, on
/// a phone, and when the server offers it or this phone already has a device.
class AppBrowserDeviceTile extends ConsumerWidget {
  const AppBrowserDeviceTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!kAppBrowserCode || !ref.watch(appBrowserOnProvider)) {
      return const SizedBox.shrink();
    }
    final st = ref.watch(appBrowserStatusProvider).value;
    if (st == null || (!st.available && st.device == null)) {
      return const SizedBox.shrink();
    }
    final l10n = context.l10n;
    final d = st.device;
    final subtitle = !st.available
        ? l10n.appBrowserSwitchedOff(appBrowserReasonText(l10n, st.reason))
        : d != null && d.enabled
        ? l10n.appBrowserOn
        : l10n.appBrowserOff;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpace.md),
      child: GroupedCard(
        children: [
          GroupedTile(
            key: const Key('appBrowserDeviceTile'),
            icon: LucideIcons.globe,
            title: l10n.appBrowserTitle,
            subtitle: subtitle,
            onTap: () => context.push('/settings/phone-browser'),
          ),
        ],
      ),
    );
  }
}

/// Asks before the first turn-on (plan §4, Apple 5.1.2(i)): what is sent where, and a clear yes.
Future<bool> showAppBrowserConsent(BuildContext context) async {
  final l10n = context.l10n;
  Widget line(IconData icon, String text) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpace.sm),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: context.colorScheme.primary),
        const SizedBox(width: AppSpace.sm),
        Expanded(
          child: Text(
            text,
            style: context.textTheme.bodyMedium?.copyWith(height: 1.4),
          ),
        ),
      ],
    ),
  );
  final ok = await showAdaptiveSheet<bool>(
    context: context,
    dialogMaxWidth: 480,
    builder: (c) => FormSheet(
      key: const Key('appBrowserConsent'),
      icon: LucideIcons.globe,
      title: l10n.appBrowserConsentTitle,
      submitLabel: l10n.allow,
      submitKey: const Key('appBrowserConsentAllow'),
      cancelLabel: l10n.notNow,
      onSubmit: () => Navigator.pop(c, true),
      children: [
        line(LucideIcons.send, l10n.appBrowserConsentPages),
        line(LucideIcons.keyRound, l10n.appBrowserConsentSignIns),
        line(LucideIcons.eye, l10n.appBrowserConsentWatch),
        line(LucideIcons.shieldCheck, l10n.appBrowserConsentYours),
      ],
    ),
  );
  return ok ?? false;
}

/// Opens the full browser: a bot's page, or with [person] the person's own browsing.
Future<void> openAppBrowser(BuildContext context, {bool person = false}) =>
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => AppBrowserScreen(person: person),
      ),
    );

/// Settings → Device connections → Browser on This Phone (plan §4, §8.7).
class AppBrowserSettingsScreen extends ConsumerStatefulWidget {
  const AppBrowserSettingsScreen({super.key});

  @override
  ConsumerState<AppBrowserSettingsScreen> createState() =>
      _AppBrowserSettingsScreenState();
}

class _AppBrowserSettingsScreenState
    extends ConsumerState<AppBrowserSettingsScreen> {
  var _busy = false;

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    await runGuarded(context, action);
    if (!mounted) return;
    ref.invalidate(appBrowserStatusProvider);
    setState(() => _busy = false);
  }

  Future<void> _turn(
    AppBrowserState st,
    bool on, {
    required bool hasToken,
  }) async {
    HapticsHelper.light();
    final l10n = context.l10n;
    final service = ref.read(appBrowserServiceProvider);
    final d = st.device;
    if (!on) {
      if (d != null) {
        await _run(
          () =>
              ref.read(backendProvider).updateAppBrowser(d.id, enabled: false),
        );
      }
      return;
    }
    if (d == null) {
      if (!await showAppBrowserConsent(context) || !mounted) return;
    }
    final name = appBrowserSystem == 'ios'
        ? l10n.appBrowserDeviceIos
        : l10n.appBrowserDeviceAndroid;
    await _run(() async {
      if (d == null) {
        await service.pair(name: name);
      } else if (!hasToken) {
        // Paired on an earlier install: this one has no token, so pair again.
        await service.unpair(d.id);
        await service.pair(name: name);
      } else {
        await ref.read(backendProvider).updateAppBrowser(d.id, enabled: true);
      }
    });
  }

  Future<void> _update(
    LocalDevice d, {
    List<String>? bots,
    List<String>? allowed,
    List<String>? blocked,
    List<String>? kinds,
  }) => _run(
    () => ref
        .read(backendProvider)
        .updateAppBrowser(
          d.id,
          botIds: bots,
          allowedSites: allowed,
          blockedSites: blocked,
          allowedKinds: kinds,
        ),
  );

  Future<void> _clearData() async {
    final l10n = context.l10n;
    final ok = await showConfirm(
      context: context,
      title: l10n.appBrowserClearDataConfirm,
      confirmLabel: l10n.appBrowserClearData,
      confirmKey: const Key('appBrowserClearDataConfirm'),
      destructive: true,
    );
    if (!ok || !mounted) return;
    final done = await runGuarded(context, () async {
      await ref.read(appBrowserProvider.notifier).clearData();
      return true;
    });
    if (done == true && mounted) {
      showSuccess(context, l10n.appBrowserClearDataDone);
    }
  }

  Future<void> _unpair(LocalDevice d) async {
    final l10n = context.l10n;
    final ok = await showConfirm(
      context: context,
      title: l10n.appBrowserUnpair,
      message: l10n.appBrowserUnpairConfirm,
      confirmLabel: l10n.appBrowserUnpair,
      confirmKey: const Key('appBrowserUnpairConfirm'),
      destructive: true,
    );
    if (!ok || !mounted) return;
    await _run(() => ref.read(appBrowserServiceProvider).unpair(d.id));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (!kAppBrowserCode || !ref.watch(appBrowserOnProvider)) {
      return SubPage(title: l10n.appBrowserTitle, children: const []);
    }
    return SubPage(
      title: l10n.appBrowserTitle,
      body: AsyncView<AppBrowserState?>(
        value: ref.watch(appBrowserStatusProvider),
        onRetry: () => ref.invalidate(appBrowserStatusProvider),
        data: (st) {
          if (st == null) return const SizedBox.shrink();
          final d = st.device;
          final support = ref.watch(_supportProvider).value;
          final hasToken = d == null
              ? false
              : ref.watch(_hasTokenProvider(d.id)).value ?? true;
          final unsupported = support != null && !support.supported;
          final on =
              d != null &&
              d.enabled &&
              st.available &&
              hasToken &&
              !unsupported;
          final canSwitch = !_busy && (on || (st.available && !unsupported));
          final subtitle = unsupported
              ? l10n.appBrowserSwitchedOff(l10n.appBrowserReasonUnsupported)
              : !st.available
              ? l10n.appBrowserSwitchedOff(
                  appBrowserReasonText(l10n, st.reason),
                )
              : d != null && !hasToken
              ? l10n.appBrowserReasonNoToken
              : l10n.appBrowserSwitchHelp;
          return PageColumn(
            children: [
              FormNote(l10n.appBrowserHelp, icon: LucideIcons.shieldCheck),
              const SizedBox(height: AppSpace.md),
              GroupedCard(
                children: [
                  GroupedTile(
                    icon: LucideIcons.globe,
                    title: l10n.appBrowserTitle,
                    subtitle: subtitle,
                    onTap: canSwitch
                        ? () => _turn(st, !on, hasToken: hasToken)
                        : null,
                    trailing: Switch(
                      key: const Key('appBrowserSwitch'),
                      value: on,
                      onChanged: canSwitch
                          ? (v) => _turn(st, v, hasToken: hasToken)
                          : null,
                    ),
                  ),
                ],
              ),
              if (d != null) ..._deviceSections(context, d, on),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _deviceSections(BuildContext context, LocalDevice d, bool on) {
    final l10n = context.l10n;
    final bots = ref.watch(botsProvider).value ?? const <Bot>[];
    final allowed = d.allowedSites ?? const <String>[];
    final blocked = d.blockedSites ?? const <String>[];
    final kinds = [
      for (final k in d.allowedKinds ?? const <SiteKind>[]) k.value,
    ];
    Widget siteRow(String site, bool always) => GroupedTile(
      key: Key('appBrowserSite-$site'),
      icon: always ? LucideIcons.circleCheck : LucideIcons.ban,
      iconColor: always
          ? context.appColors.positive
          : context.appColors.negative,
      title: site,
      subtitle: always ? l10n.appBrowserAlways : l10n.appBrowserNever,
      trailing: IconButton(
        key: Key('appBrowserRemoveSite-$site'),
        tooltip: l10n.appBrowserRemoveSite(site),
        icon: const Icon(LucideIcons.x, size: 18),
        onPressed: _busy
            ? null
            : () => always
                  ? _update(d, allowed: [...allowed]..remove(site))
                  : _update(d, blocked: [...blocked]..remove(site)),
      ),
    );
    return [
      const SizedBox(height: AppSpace.md),
      SectionHeader(title: l10n.appBrowserBots),
      if (bots.isEmpty)
        FormNote(l10n.appBrowserNoBots)
      else
        GroupedCard(
          children: [
            for (final b in bots)
              GroupedTile(
                key: Key('appBrowserBotRow-${b.id}'),
                icon: LucideIcons.bot,
                title: b.name,
                trailing: Switch(
                  key: Key('appBrowserBot-${b.id}'),
                  value: d.allowedBotIds.contains(b.id),
                  onChanged: _busy
                      ? null
                      : hapticOnChanged(
                          (v) => _update(
                            d,
                            bots: v
                                ? [...d.allowedBotIds, b.id]
                                : [
                                    ...d.allowedBotIds.where(
                                      (id) => id != b.id,
                                    ),
                                  ],
                          ),
                        ),
                ),
              ),
          ],
        ),
      Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.xxs,
          AppSpace.xs,
          AppSpace.xxs,
          0,
        ),
        child: FormNote(l10n.appBrowserBotsHelp),
      ),
      const SizedBox(height: AppSpace.md),
      SectionHeader(title: l10n.appBrowserSites),
      if (allowed.isEmpty && blocked.isEmpty)
        FormNote(l10n.appBrowserNoSites)
      else ...[
        GroupedCard(
          children: [
            for (final s in allowed) siteRow(s, true),
            for (final s in blocked) siteRow(s, false),
          ],
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.xxs,
            AppSpace.xs,
            AppSpace.xxs,
            0,
          ),
          child: FormNote(l10n.appBrowserSitesHelp),
        ),
      ],
      const SizedBox(height: AppSpace.md),
      SectionHeader(title: l10n.appBrowserKinds),
      GroupedCard(
        children: [
          for (final k in _kinds)
            GroupedTile(
              icon: switch (k) {
                'banking' => LucideIcons.landmark,
                'health' => LucideIcons.heartPulse,
                'passwords' => LucideIcons.keyRound,
                _ => LucideIcons.idCard,
              },
              title: appBrowserKindLabel(l10n, k),
              trailing: Switch(
                key: Key('appBrowserKind-$k'),
                value: kinds.contains(k),
                onChanged: _busy
                    ? null
                    : hapticOnChanged(
                        (v) => _update(
                          d,
                          kinds: v
                              ? [...kinds, k]
                              : [...kinds.where((x) => x != k)],
                        ),
                      ),
              ),
            ),
        ],
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.xxs,
          AppSpace.xs,
          AppSpace.xxs,
          0,
        ),
        child: FormNote(l10n.appBrowserKindsHelp),
      ),
      const SizedBox(height: AppSpace.md),
      GroupedCard(
        children: [
          GroupedTile(
            key: const Key('appBrowserSignIn'),
            icon: LucideIcons.logIn,
            title: l10n.appBrowserSignIn,
            subtitle: l10n.appBrowserSignInHelp,
            onTap: on ? () => openAppBrowser(context, person: true) : null,
          ),
          GroupedTile(
            key: const Key('appBrowserClearData'),
            icon: LucideIcons.eraser,
            title: l10n.appBrowserClearData,
            subtitle: l10n.appBrowserClearDataHelp,
            onTap: _clearData,
          ),
          GroupedTile(
            key: const Key('appBrowserUnpair'),
            icon: LucideIcons.unlink,
            title: l10n.appBrowserUnpair,
            destructive: true,
            onTap: _busy ? null : () => _unpair(d),
          ),
        ],
      ),
    ];
  }
}
