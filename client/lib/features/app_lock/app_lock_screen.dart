import 'package:flutter/foundation.dart';
import 'package:casama_sdk/casama_sdk.dart' show OrgRole, OrganizationWithRole;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/backend.dart';
import '../../core/haptics.dart';
import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../ui/app_card.dart';
import '../../ui/form_sheet.dart';
import '../../ui/page.dart';
import '../notifications/push_prefs.dart';
import 'app_lock.dart';
import 'confirm_identity.dart';
import 'lock_screen.dart';
import 'pin_store.dart';

final _requireAppLockProvider = FutureProvider.autoDispose<bool?>((ref) async {
  final org = ref.watch(currentOrgProvider);
  if (org == null || org.role == OrgRole.member) return null;
  return ref.watch(backendProvider).requireAppLock(org.id);
});

String lockAfterLabel(AppLocalizations l10n, LockAfter after) =>
    switch (after) {
      LockAfter.immediately => l10n.appLockAfterImmediately,
      LockAfter.oneMinute => l10n.appLockAfterOneMinute,
      LockAfter.fiveMinutes => l10n.appLockAfterFiveMinutes,
      LockAfter.fifteenMinutes => l10n.appLockAfterFifteenMinutes,
      LockAfter.oneHour => l10n.appLockAfterOneHour,
    };

/// Settings → App lock (D-375).
class AppLockScreen extends ConsumerStatefulWidget {
  const AppLockScreen({super.key});

  @override
  ConsumerState<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends ConsumerState<AppLockScreen> {
  var _busy = false;

  AppLockSettings get _settings => ref.read(appLockSettingsProvider);
  Future<void> _save(AppLockSettings s) =>
      ref.read(appLockSettingsProvider.notifier).save(s);

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _setEnabled(bool on) => _run(() async {
    if (on) {
      if (await turnOnAppLock(context, ref) && mounted) {
        showSuccess(context, context.l10n.appLockTurnedOn);
      }
      return;
    }
    // Turning it off takes the same check as unlocking.
    if (!await confirmIdentity(context, ref, always: true)) return;
    await _save(_settings.off);
    await PinStore.clear();
  });

  Future<void> _changePin() => _run(() async {
    if (!await confirmIdentity(context, ref, always: true) || !mounted) return;
    final pin = await showPinSetup(context);
    if (pin == null || !mounted) return;
    if (await PinStore.save(pin)) {
      if (mounted) showSuccess(context, context.l10n.appLockPinChanged);
    } else if (mounted) {
      showMessage(context, context.l10n.appLockPinNotSaved);
    }
  });

  Future<void> _setAskBeforeRisky(bool on) => _run(() async {
    if (!on && !await confirmIdentity(context, ref, always: true)) return;
    await _save(_settings.copyWith(askBeforeRisky: on));
  });

  Future<void> _setRequired(OrganizationWithRole org, bool on) =>
      _run(() async {
        final l10n = context.l10n;
        // Your own device first, as with two-step sign-in: requiring it would lock you out otherwise.
        if (on && !_settings.activeFor(ref.read(backendProvider).userId)) {
          showMessage(context, l10n.requireAppLockOwnFirst);
          return;
        }
        await runGuarded(
          context,
          () => ref.read(backendProvider).setRequireAppLock(org.id, on),
        );
        ref.invalidate(_requireAppLockProvider);
        ref.invalidate(organizationsProvider);
      });

  Future<void> _setHideReplies(PushPrefs prefs, bool on) => _run(() async {
    await runGuarded(
      context,
      () => ref
          .read(backendProvider)
          .setPushPrefs(prefs.copyWith(hideReplyText: on)),
    );
    ref.invalidate(pushPrefsProvider);
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    final settings = ref.watch(appLockSettingsProvider);
    final on = settings.activeFor(ref.watch(backendProvider).userId);
    final requiredBy = ref.watch(appLockRequiredByProvider);
    final org = ref.watch(currentOrgProvider);
    final require = ref.watch(_requireAppLockProvider).value;
    final pushPrefs = ref.watch(pushPrefsProvider).value;
    final method = switch (settings.method) {
      LockMethod.device => l10n.appLockMethodDevice(deviceUnlockName(l10n)),
      LockMethod.pin => l10n.appLockMethodPin,
      LockMethod.passkey => l10n.appLockMethodPasskey,
    };
    final android = !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    return SubPage(
      title: l10n.appLock,
      children: [
        FormNote(l10n.appLockHelp, icon: LucideIcons.lock),
        SectionHeader(title: l10n.thisDevice),
        GroupedCard(
          children: [
            GroupedTile(
              icon: LucideIcons.lock,
              title: l10n.appLockSwitch,
              subtitle: on && requiredBy != null
                  ? l10n.appLockRequiredBy(requiredBy)
                  : (on ? method : l10n.appLockRow),
              trailing: Switch(
                key: const Key('appLockSwitch'),
                value: on,
                // A workspace that requires it keeps it on.
                onChanged: _busy || (on && requiredBy != null)
                    ? null
                    : hapticOnChanged(_setEnabled),
              ),
            ),
            if (on) ...[
              GroupedTile(
                icon: LucideIcons.timer,
                title: l10n.appLockAfter,
                subtitle: l10n.appLockAfterHelp,
                trailing: PopupMenuButton<LockAfter>(
                  key: const Key('appLockAfter'),
                  initialValue: settings.after,
                  onSelected: (v) => _save(_settings.copyWith(after: v)),
                  itemBuilder: (_) => [
                    for (final a in LockAfter.values)
                      PopupMenuItem(
                        key: Key('appLockAfter-${a.name}'),
                        value: a,
                        child: Text(lockAfterLabel(l10n, a)),
                      ),
                  ],
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          lockAfterLabel(l10n, settings.after),
                          style: context.textTheme.bodyMedium?.copyWith(
                            color: scheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Icon(
                          LucideIcons.chevronDown,
                          size: 16,
                          color: scheme.primary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (settings.method == LockMethod.pin)
                GroupedTile(
                  key: const Key('appLockChangePin'),
                  icon: LucideIcons.keyRound,
                  title: l10n.appLockChangePin,
                  onTap: _busy ? null : _changePin,
                ),
              if (android)
                GroupedTile(
                  icon: LucideIcons.eyeOff,
                  title: l10n.appLockBlockScreenshots,
                  subtitle: l10n.appLockBlockScreenshotsHelp,
                  trailing: Switch(
                    key: const Key('appLockBlockScreenshots'),
                    value: settings.blockScreenshots,
                    onChanged: hapticOnChanged(
                      (v) => _save(_settings.copyWith(blockScreenshots: v)),
                    ),
                  ),
                ),
              GroupedTile(
                key: const Key('appLockLockNow'),
                icon: LucideIcons.lockKeyhole,
                title: l10n.appLockLockNow,
                showChevron: false,
                onTap: () {
                  HapticsHelper.light();
                  ref.read(appLockProvider.notifier).lock();
                },
              ),
            ],
          ],
        ),
        SectionHeader(title: l10n.appLockPrivacySection),
        GroupedCard(
          children: [
            GroupedTile(
              icon: LucideIcons.shieldCheck,
              title: l10n.appLockAskBeforeRisky,
              subtitle: l10n.appLockAskBeforeRiskyHelp,
              trailing: Switch(
                key: const Key('appLockAskBeforeRisky'),
                value: settings.askBeforeRisky,
                onChanged: _busy ? null : hapticOnChanged(_setAskBeforeRisky),
              ),
            ),
            if (pushPrefs != null)
              GroupedTile(
                icon: LucideIcons.bellOff,
                title: l10n.pushHideReplyText,
                subtitle: l10n.pushHideReplyTextHelp,
                trailing: Switch(
                  key: const Key('appLockHideReplies'),
                  value: pushPrefs.hideReplyText,
                  onChanged: _busy
                      ? null
                      : hapticOnChanged((v) => _setHideReplies(pushPrefs, v)),
                ),
              ),
          ],
        ),
        if (require != null && org != null) ...[
          SectionHeader(title: l10n.workspace),
          GroupedCard(
            children: [
              GroupedTile(
                icon: LucideIcons.building2,
                title: l10n.requireAppLock,
                subtitle: l10n.requireAppLockHelp,
                trailing: Switch(
                  key: const Key('requireAppLock'),
                  value: require,
                  onChanged: _busy
                      ? null
                      : hapticOnChanged((v) => _setRequired(org, v)),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
