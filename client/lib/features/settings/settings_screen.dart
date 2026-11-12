import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:casama_sdk/casama_sdk.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../voice/call_tools_sheet.dart';
import '../chat/chat_detail.dart';
import '../../core/billing.dart';
import '../../core/mac_bridge.dart';
import '../../core/updater.dart';
import '../../core/display_text.dart';
import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../core/haptics.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../ui/adaptive_modal.dart';
import '../../ui/advanced_section.dart';
import '../../ui/form_sheet.dart';
import '../voice/wake_word.dart';
import '../voice/wake_word_sheet.dart';
import '../../ui/page.dart';
import 'about_you_screen.dart';
import 'appearance_screen.dart';
import 'me_avatar.dart';
import 'version_indicator.dart';
import '../../ui/app_card.dart';
import '../../ui/shell_header.dart';
import '../admin/admin_screen.dart';
import '../notifications/quiet_hours.dart';
import '../companion/companion.dart';
import '../referrals/invite_friends.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key, this.pane = false, this.current = ''});

  /// The list beside an open settings page on wide windows: one column, the open page highlighted,
  /// and rows swap the page next to it instead of stacking a new one.
  final bool pane;

  /// The location of the page open next to the pane.
  final String current;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final backend = ref.watch(backendProvider);
    final org = ref.watch(currentOrgProvider);
    final orgs = ref.watch(organizationsProvider).value ?? const <OrganizationWithRole>[];
    final month = ref.watch(usageMonthProvider).value;
    final isAdmin = org != null && org.role != OrgRole.member;
    final billing = ref.watch(billingProvider).value;
    final referral = ref.watch(referralProvider).value;
    final scheme = context.colorScheme;
    final email = backend.userEmail ?? '';
    final colors = context.appColors;
    void open(String path) => pane ? context.go(path) : context.push(path);
    bool sel(String path) => pane && current.startsWith(path);
    return Scaffold(
      // Opened from the person's avatar, not a tab (D-176): phones always get a way back.
      appBar: ShellHeader(title: l10n.settings, phoneFallback: pane ? null : '/bots'),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Wide windows: the groups sit in two columns instead of one long, narrow list.
          final twoColumns = !pane && constraints.maxWidth >= kTwoColumnMinWidth;
          final side = AppSpace.gutter + AppBreakpoints.centeringInset(constraints.maxWidth, maxWidth: twoColumns ? kWidePageMaxWidth : kPageMaxWidth);
          // About you (D-169): the name bots use, and the way into the profile.
          final name = ref.watch(aboutYouProvider).value?.name ?? '';
          final profile = AppCard(
                key: const Key('settingsAboutYou'),
                onTap: () => open('/settings/about-you'),
                padding: const EdgeInsets.all(AppSpace.md),
                child: Row(
                  children: [
                    const MeAvatar(size: 52),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name.isNotEmpty ? name : email,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            [if (name.isNotEmpty) email, org?.name ?? '', if (org != null) _roleLabel(context, org.role)].where((s) => s.isNotEmpty).join(' · '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                          const SizedBox(height: 2),
                          Text(l10n.aboutYouRow, style: context.textTheme.bodySmall?.copyWith(color: scheme.primary, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    Icon(LucideIcons.chevronRight, color: scheme.onSurfaceVariant.withValues(alpha: 0.7)),
                  ],
                ),
              );
          // Most-used first (D-176): the workspace, how the app behaves, what bots connect to, then
          // sign-in and security, with the rarely needed options folded under Advanced (D-182). Two
          // columns on wide windows.
          final left = <Widget>[
              SectionHeader(title: l10n.workspace),
              GroupedCard(
                children: [
                  GroupedTile(
                    icon: LucideIcons.boxes,
                    title: org?.name ?? l10n.workspace,
                    subtitle: orgs.length > 1 ? l10n.switchWorkspace : null,
                    trailing: orgs.length > 1
                        ? PopupMenuButton<String>(
                            tooltip: l10n.switchWorkspace,
                            icon: Icon(LucideIcons.chevronsUpDown, color: scheme.onSurfaceVariant),
                            onSelected: (id) => ref.read(selectedOrgIdProvider.notifier).select(id),
                            itemBuilder: (_) => [for (final o in orgs) PopupMenuItem(value: o.id, child: Text(o.name))],
                          )
                        : null,
                  ),
                  GroupedTile(
                    key: const Key('settingsPeople'),
                    icon: isAdmin ? LucideIcons.userPlus : LucideIcons.users,
                    title: l10n.people,
                    subtitle: isAdmin ? l10n.peopleRow : null,
                    showChevron: true,
                    onTap: () => open('/settings/people'), selected: sel('/settings/people'),
                  ),
                  GroupedTile(
                    key: const Key('settingsWorkspace'),
                    icon: LucideIcons.palette,
                    title: l10n.workspaceSettings,
                    subtitle: l10n.workspaceSettingsHelp,
                    showChevron: true,
                    onTap: () => open('/settings/workspace'), selected: sel('/settings/workspace'),
                  ),
                  GroupedTile(
                    key: const Key('settingsUsage'),
                    icon: LucideIcons.banknote,
                    iconColor: colors.positive,
                    onTap: () => open('/settings/usage'), selected: sel('/settings/usage'),
                    showChevron: true,
                    title: l10n.usage,
                    trailing: Text(
                      formatUsd(month?.totalCostUsd ?? 0, context.l10n.localeName),
                      style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700, fontFeatures: AppText.tabular),
                    ),
                    subtitle: l10n.usageSubtitle,
                  ),
                  if (billing?.enabled ?? false)
                    GroupedTile(
                      key: const Key('settingsBilling'),
                      icon: LucideIcons.gem,
                      iconColor: colors.warning,
                      title: l10n.billing,
                      subtitle: billing!.planName,
                      onTap: () => open('/settings/billing'), selected: sel('/settings/billing'),
                    ),
                  // Invite friends (D-211): Casama Cloud only.
                  if (referral?.enabled ?? false)
                    GroupedTile(
                      key: const Key('settingsInvite'),
                      icon: LucideIcons.gift,
                      iconColor: scheme.primary,
                      title: l10n.inviteFriends,
                      subtitle: referral!.rewardUsd > 0
                          ? l10n.inviteFriendsRow(formatUsd(referral.rewardUsd, l10n.localeName))
                          : l10n.inviteFriendsRowPlain,
                      showChevron: true,
                      onTap: () => open('/settings/invite'), selected: sel('/settings/invite'),
                    ),
                  if (ref.watch(adminOverviewProvider).value != null)
                    GroupedTile(key: const Key('settingsAdmin'), icon: LucideIcons.shieldUser, title: l10n.adminConsole, subtitle: l10n.adminRowHelp, onTap: () => open('/settings/admin'), selected: sel('/settings/admin')),
                ],
              ),
              SectionHeader(title: l10n.settingsAppSection),
              GroupedCard(
                children: [
                  GroupedTile(
                    key: const Key('settingsAppearance'),
                    icon: LucideIcons.swatchBook,
                    title: l10n.appearance,
                    subtitle: appearanceSummary(context, ref),
                    onTap: () => open('/settings/appearance'), selected: sel('/settings/appearance'),
                  ),
                  GroupedTile(
                    key: const Key('settingsQuietHours'),
                    icon: LucideIcons.moon,
                    title: l10n.quietHours,
                    subtitle: switch (ref.watch(quietHoursProvider).value) {
                      final q? => quietSummary(context, q),
                      null => l10n.off,
                    },
                    onTap: () => showQuietHours(context, ref),
                  ),
                  // Wake word (D-144): desktop and Android.
                  if (wakeWordSupported)
                    GroupedTile(
                      key: const Key('settingsWakeWord'),
                      icon: LucideIcons.audioLines,
                      title: l10n.wakeWord,
                      subtitle: ref.watch(wakeWordProvider).enabled ? l10n.wakeWordOnRow(ref.watch(wakeWordProvider).phrase) : l10n.wakeWordRow,
                      onTap: () => showAdaptiveSheet<void>(context: context, builder: (_) => const WakeWordSheet()),
                    ),
                  // Off by default: chats show what the bot is doing, not each step (D-162).
                  SwitchListTile(
                    key: const Key('showBotSteps'),
                    secondary: Icon(LucideIcons.listTree, color: scheme.onSurfaceVariant),
                    title: Text(l10n.showBotSteps),
                    subtitle: Text(l10n.showBotStepsHelp),
                    value: ref.watch(showBotStepsProvider),
                    onChanged: hapticOnChanged(ref.read(showBotStepsProvider.notifier).set),
                  ),
                  // Desktop downloads update themselves (the stores update theirs); Linux is told.
                  if (selfUpdating || updateNoticeOnly) const _UpdatesRows(),
                  // Mac: start with the system, ready for the quick-ask shortcut and the menu bar icon.
                  if (ref.watch(launchAtLoginProvider).value case final on?)
                    SwitchListTile(
                      key: const Key('openAtLogin'),
                      secondary: Icon(LucideIcons.power, color: scheme.onSurfaceVariant),
                      title: Text(l10n.openAtLogin),
                      subtitle: Text(l10n.openAtLoginHelp),
                      value: on,
                      onChanged: hapticOnChanged((v) async {
                        await runGuarded(context, () => setLaunchAtLogin(v));
                        ref.invalidate(launchAtLoginProvider);
                      }),
                    ),
                  GroupedTile(
                    icon: LucideIcons.languages,
                    title: l10n.language,
                    trailing: Text(_languageName(Localizations.localeOf(context)), style: context.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
                  ),
                ],
              ),
          ];
          final right = <Widget>[
              SectionHeader(title: l10n.settingsConnectionsSection),
              GroupedCard(
                children: [
                  GroupedTile(
                    key: const Key('settingsIntegrations'),
                    icon: LucideIcons.puzzle,
                    title: l10n.integrations,
                    subtitle: l10n.integrationsRowHelp,
                    onTap: () => open('/settings/integrations'), selected: sel('/settings/integrations'),
                  ),
                  GroupedTile(icon: LucideIcons.bookOpen, title: l10n.skills, subtitle: l10n.skillsRowHelp, onTap: () => open('/settings/skills'), selected: sel('/settings/skills')),
                  GroupedTile(icon: LucideIcons.keyRound, title: l10n.modelKeys, subtitle: l10n.modelKeysHelp, onTap: () => open('/settings/keys'), selected: sel('/settings/keys')),
                ],
              ),
              SectionHeader(title: l10n.settingsSecuritySection),
              GroupedCard(
                children: [
                  GroupedTile(
                    key: const Key('settingsAccount'),
                    icon: LucideIcons.circleUser,
                    title: l10n.account,
                    subtitle: backend.userEmail.orPlaceholder(l10n.accountRow),
                    onTap: () => open('/settings/account'), selected: sel('/settings/account'),
                  ),
                  GroupedTile(
                    key: const Key('settingsTwoStep'),
                    icon: LucideIcons.smartphone,
                    title: l10n.twoStepSignIn,
                    subtitle: org?.requireMfa == true && org?.role != OrgRole.member && !backend.twoStepVerified ? l10n.twoStepNeededForAdmin : l10n.twoStepHelp,
                    onTap: () => open('/settings/two-step'), selected: sel('/settings/two-step'),
                  ),
                  // Passkeys (D-183): when the server has them and this device can make them.
                  if (ref.watch(authMethodsProvider).value?.passkeys == true)
                    GroupedTile(
                      key: const Key('settingsPasskeys'),
                      icon: LucideIcons.keyRound,
                      title: l10n.passkeys,
                      subtitle: l10n.passkeysRow,
                      onTap: () => open('/settings/passkeys'), selected: sel('/settings/passkeys'),
                    ),
                  GroupedTile(key: const Key('settingsPrivacy'), icon: LucideIcons.shieldCheck, title: l10n.privacy, subtitle: l10n.privacyRowHelp, onTap: () => open('/settings/privacy'), selected: sel('/settings/privacy')),
                ],
              ),
              // Everything most people never need, in one fold that stays open once opened (D-182).
              AdvancedSection(
                id: 'settings',
                summary: l10n.settingsAdvancedSummary,
                // Beside an open page inside it (wide windows), it stays open so the row shows.
                forceOpen: const ['/settings/secrets', '/settings/computers', '/settings/devices', '/settings/companion'].any(sel),
                children: [
                  GroupedCard(
                    children: [
                      GroupedTile(key: const Key('settingsSecrets'), icon: LucideIcons.lock, title: l10n.secrets, subtitle: l10n.secretsRowHelp, onTap: () => open('/settings/secrets'), selected: sel('/settings/secrets')),
                      GroupedTile(key: const Key('settingsComputers'), icon: LucideIcons.monitor, title: l10n.computers, subtitle: l10n.computersRowHelp, onTap: () => open('/settings/computers'), selected: sel('/settings/computers')),
                      // Device connections (D-149): data this device shares with your bots.
                      GroupedTile(
                        key: const Key('settingsDevices'),
                        icon: LucideIcons.smartphone,
                        title: l10n.deviceConnections,
                        subtitle: l10n.deviceConnectionsRowHelp,
                        onTap: () => open('/settings/devices'), selected: sel('/settings/devices'),
                      ),
                      if (ref.watch(companionProvider).supported)
                        GroupedTile(
                          key: const Key('settingsCompanion'),
                          icon: LucideIcons.laptop,
                          title: l10n.useThisComputer,
                          subtitle: l10n.companionRowHelp,
                          onTap: () => open('/settings/companion'), selected: sel('/settings/companion'),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.lg),
              GroupedCard(
                children: [
                  GroupedTile(
                    icon: LucideIcons.logOut,
                    title: l10n.signOut,
                    destructive: true,
                    showChevron: false,
                    onTap: () async {
                      final ok = await showConfirm(context: context, title: l10n.signOut, message: l10n.signOutConfirm, confirmLabel: l10n.signOut, destructive: true);
                      if (ok && context.mounted) await runGuarded(context, backend.signOut);
                    },
                  ),
                ],
              ),
          ];
          return ListView(
            padding: EdgeInsets.fromLTRB(side, AppSpace.xs, side, AppSpace.xxl + MediaQuery.paddingOf(context).bottom),
            children: [
              profile,
              if (twoColumns)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: left)),
                    const SizedBox(width: AppSpace.xl),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: right)),
                  ],
                )
              else ...[...left, ...right],
              // The version and build, for bug reports (a tap copies it).
              const SizedBox(height: AppSpace.md),
              const Center(child: VersionIndicator()),
            ],
          );
        },
      ),
    );
  }
}

String _languageName(Locale locale) => switch (locale.languageCode) {
  'en' => 'English',
  _ => locale.toLanguageTag(),
};

String _roleLabel(BuildContext context, OrgRole role) => switch (role) {
  OrgRole.owner => context.l10n.roleOwner,
  OrgRole.admin => context.l10n.roleAdmin,
  _ => context.l10n.roleMember,
};

/// A bot's read-aloud and dictation providers (each uses the workspace's own key).
class VoiceSettingsDialog extends ConsumerStatefulWidget {
  const VoiceSettingsDialog({super.key, required this.botId});
  final String botId;

  @override
  ConsumerState<VoiceSettingsDialog> createState() => _VoiceSettingsDialogState();
}

class _VoiceSettingsDialogState extends ConsumerState<VoiceSettingsDialog> {
  String? _tts;
  String? _stt;
  final _voice = TextEditingController();
  var _busy = false;
  var _callTools = <String>[];
  var _loaded = false;

  @override
  void initState() {
    super.initState();
    // Start from the bot's current settings rather than Automatic.
    ref.read(backendProvider).loadBotVoice(widget.botId).then((v) {
      if (!mounted) return;
      setState(() {
        _tts = v['tts_provider'] as String?;
        _stt = v['stt_provider'] as String?;
        _voice.text = (v['tts_voice'] as String?) ?? '';
        _callTools = [for (final t in (v['call_tools'] as List?) ?? const []) '$t'];
        _loaded = true;
      });
    }).catchError((_) {
      if (mounted) setState(() => _loaded = true);
    });
  }

  @override
  void dispose() {
    _voice.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    final ok = await runGuarded(context, () async {
      // Null clears a setting (Automatic); the bot's other voice settings are kept.
      await ref.read(backendProvider).updateBotVoice(widget.botId, {'tts_provider': _tts, 'stt_provider': _stt, 'tts_voice': _voice.text.trim().isEmpty ? null : _voice.text.trim()});
      return true;
    });
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok == true) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cloud = ref.watch(billingProvider).value?.enabled == true;
    String label(String p) => switch (p) {
      'google' => 'Google',
      'elevenlabs' => 'ElevenLabs',
      'openai' => 'OpenAI',
      'cartesia' => 'Cartesia',
      'fish_audio' => 'Fish Audio',
      'deepgram' => 'Deepgram',
      _ => p,
    };
    return FormSheet(
      icon: LucideIcons.speech,
      title: l10n.voiceSettings,
      subtitle: l10n.voiceSettingsHelp,
      submitLabel: l10n.save,
      submitKey: const Key('saveVoice'),
      busy: _busy,
      onSubmit: _save,
      children: [
        if (cloud)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpace.md),
            child: Text(l10n.casamaCloudModelLocked),
          ),
        if (!cloud)
        DropdownButtonFormField<String?>(
          isExpanded: true,
          key: const Key('ttsProvider'),
          initialValue: _tts,
          decoration: InputDecoration(labelText: l10n.readAloudProvider, prefixIcon: const Icon(LucideIcons.volume2, size: 20)),
          items: [
            DropdownMenuItem(value: null, child: Text(l10n.automatic)),
            for (final p in const ['google', 'elevenlabs', 'openai', 'cartesia', 'fish_audio']) DropdownMenuItem(value: p, child: Text(label(p))),
          ],
          onChanged: hapticOnChanged((v) => setState(() => _tts = v), haptic: HapticsHelper.selection),
        ),
        TextField(
          controller: _voice,
          decoration: InputDecoration(labelText: l10n.voiceId, helperText: l10n.voiceIdHelp, prefixIcon: const Icon(LucideIcons.audioLines, size: 20)),
        ),
        if (!cloud)
        DropdownButtonFormField<String?>(
          isExpanded: true,
          key: const Key('sttProvider'),
          initialValue: _stt,
          decoration: InputDecoration(labelText: l10n.dictationProvider, prefixIcon: const Icon(LucideIcons.mic, size: 20)),
          items: [
            DropdownMenuItem(value: null, child: Text(l10n.automatic)),
            for (final p in const ['openai', 'deepgram']) DropdownMenuItem(value: p, child: Text(label(p))),
          ],
          onChanged: hapticOnChanged((v) => setState(() => _stt = v), haptic: HapticsHelper.selection),
        ),
        ListTile(
          key: const Key('callToolsRow'),
          contentPadding: EdgeInsets.zero,
          leading: const Icon(LucideIcons.wrench, size: 20),
          title: Text(l10n.callTools),
          subtitle: Text(l10n.callToolsCount(_callTools.length)),
          trailing: const Icon(LucideIcons.chevronRight, size: 18),
          enabled: _loaded,
          onTap: () async {
            final chosen = await showAdaptiveSheet<List<String>>(
              context: context,
              builder: (_) => CallToolsSheet(botId: widget.botId, initial: _callTools),
            );
            if (chosen != null && mounted) setState(() => _callTools = chosen);
          },
        ),
      ],
    );
  }
}

/// Updates for the desktop downloads: the version, "Check for updates" and automatic updates; on
/// Linux, a newer release when there is one.
class _UpdatesRows extends ConsumerWidget {
  const _UpdatesRows();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    final version = ref.watch(appVersionProvider).value ?? '';
    if (updateNoticeOnly) {
      final newer = ref.watch(newerReleaseProvider).value;
      return GroupedTile(
        key: const Key('settingsUpdates'),
        icon: LucideIcons.download,
        title: newer == null ? l10n.upToDate : l10n.updateReady(newer.version),
        subtitle: l10n.appVersion(version),
        showChevron: newer != null,
        onTap: newer == null ? null : () => launchUrl(newer.page, mode: LaunchMode.externalApplication),
      );
    }
    final auto = ref.watch(autoUpdateChecksProvider).value;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GroupedTile(
          key: const Key('settingsCheckUpdates'),
          icon: LucideIcons.download,
          title: l10n.checkForUpdates,
          subtitle: l10n.appVersion(version),
          showChevron: false,
          onTap: () => runGuarded(context, checkForUpdatesNow),
        ),
        if (auto != null)
          SwitchListTile(
            key: const Key('autoUpdates'),
            secondary: Icon(LucideIcons.refreshCw, color: scheme.onSurfaceVariant),
            title: Text(l10n.autoUpdates),
            subtitle: Text(l10n.autoUpdatesHelp),
            value: auto,
            onChanged: hapticOnChanged((v) async {
              await runGuarded(context, () => setAutoUpdateChecks(v));
              ref.invalidate(autoUpdateChecksProvider);
            }),
          ),
      ],
    );
  }
}

