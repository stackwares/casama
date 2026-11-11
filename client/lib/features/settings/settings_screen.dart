import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:casama_sdk/casama_sdk.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../voice/call_tools_sheet.dart';
import '../chat/chat_detail.dart';
import '../../core/backend.dart';
import '../../core/billing.dart';
import '../../core/mac_bridge.dart';
import '../../core/updater.dart';
import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../theme/appearance.dart';
import '../../theme/presets.dart';
import '../../theme/wallpaper.dart';
import '../../ui/adaptive_modal.dart';
import '../../ui/bot_avatar.dart';
import '../../ui/form_sheet.dart';
import '../bots/a2a_sheet.dart';
import '../voice/wake_word.dart';
import '../voice/wake_word_sheet.dart';
import '../bots/template_picker.dart';
import '../bots/bot_template.dart';
import '../../ui/mascot.dart';
import '../../ui/page.dart';
import '../bots/model_picker.dart';
import 'about_you_screen.dart';
import 'model_keys_screen.dart';
import 'theme_screen.dart';
import '../../ui/app_card.dart';
import '../../ui/segmented.dart';
import '../../ui/shell_header.dart';
import '../admin/admin_screen.dart';
import '../notifications/quiet_hours.dart';
import '../notifications/checkins_sheet.dart';
import '../companion/companion.dart';
import '../../ui/glow_button.dart';

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
    final scheme = context.colorScheme;
    final email = backend.userEmail ?? '';
    final colors = context.appColors;
    void open(String path) => pane ? context.go(path) : context.push(path);
    bool sel(String path) => pane && current.startsWith(path);
    return Scaffold(
      appBar: ShellHeader(title: l10n.settings),
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
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(color: scheme.primary.withValues(alpha: 0.16), shape: BoxShape.circle),
                      alignment: Alignment.center,
                      child: Text(
                        name.isNotEmpty ? name.characters.first.toUpperCase() : (email.isEmpty ? '?' : email.characters.first.toUpperCase()),
                        style: context.textTheme.titleLarge?.copyWith(color: scheme.primary, fontWeight: FontWeight.w800),
                      ),
                    ),
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
              ).appCardEntrance();
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
                      formatUsd(month?.totalCostUsd ?? 0),
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
                ],
              ),
              SectionHeader(title: l10n.settingsBotsSection),
              GroupedCard(
                children: [
                  GroupedTile(icon: LucideIcons.keyRound, title: l10n.modelKeys, subtitle: l10n.modelKeysHelp, onTap: () => open('/settings/keys'), selected: sel('/settings/keys')),
                  GroupedTile(icon: LucideIcons.bookOpen, title: l10n.skills, subtitle: l10n.skillsRowHelp, onTap: () => open('/settings/skills'), selected: sel('/settings/skills')),
                  GroupedTile(
                    key: const Key('settingsIntegrations'),
                    icon: LucideIcons.puzzle,
                    title: l10n.integrations,
                    subtitle: l10n.integrationsRowHelp,
                    onTap: () => open('/settings/integrations'), selected: sel('/settings/integrations'),
                  ),
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
                  // Wake word (D-144): desktop and Android.
                  if (wakeWordSupported)
                    GroupedTile(
                      key: const Key('settingsWakeWord'),
                      icon: LucideIcons.audioLines,
                      title: l10n.wakeWord,
                      subtitle: ref.watch(wakeWordProvider).enabled ? l10n.wakeWordOnRow(ref.watch(wakeWordProvider).phrase) : l10n.wakeWordRow,
                      onTap: () => showAdaptiveSheet<void>(context: context, builder: (_) => const WakeWordSheet()),
                    ),
                ],
              ),
          ];
          final right = <Widget>[
              SectionHeader(title: l10n.appearance),
              const _AppearanceCard(),
              SectionHeader(title: l10n.settingsMoreSection),
              GroupedCard(
                children: [
                  // Off by default: chats show what the bot is doing, not each step (D-162).
                  SwitchListTile(
                    key: const Key('showBotSteps'),
                    secondary: Icon(LucideIcons.listTree, color: scheme.onSurfaceVariant),
                    title: Text(l10n.showBotSteps),
                    subtitle: Text(l10n.showBotStepsHelp),
                    value: ref.watch(showBotStepsProvider),
                    onChanged: ref.read(showBotStepsProvider.notifier).set,
                  ),
                  GroupedTile(
                    key: const Key('settingsQuietHours'),
                    icon: LucideIcons.moon,
                    title: l10n.quietHours,
                    subtitle: ref.watch(quietHoursProvider).whenOrNull(data: (q) => quietSummary(context, q)) ?? l10n.quietHoursHelp,
                    onTap: () => showQuietHours(context, ref),
                  ),
                  GroupedTile(
                    key: const Key('settingsTwoStep'),
                    icon: LucideIcons.smartphone,
                    title: l10n.twoStepSignIn,
                    subtitle: org?.requireMfa == true && org?.role != OrgRole.member && !backend.twoStepVerified ? l10n.twoStepNeededForAdmin : l10n.twoStepHelp,
                    onTap: () => open('/settings/two-step'), selected: sel('/settings/two-step'),
                  ),
                  GroupedTile(key: const Key('settingsPrivacy'), icon: LucideIcons.shieldCheck, title: l10n.privacy, subtitle: l10n.privacyRowHelp, onTap: () => open('/settings/privacy'), selected: sel('/settings/privacy')),
                  if (ref.watch(adminOverviewProvider).value != null)
                    GroupedTile(key: const Key('settingsAdmin'), icon: LucideIcons.shieldUser, title: l10n.adminConsole, subtitle: l10n.adminRowHelp, onTap: () => open('/settings/admin'), selected: sel('/settings/admin')),
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
                      onChanged: (v) async {
                        await runGuarded(context, () => setLaunchAtLogin(v));
                        ref.invalidate(launchAtLoginProvider);
                      },
                    ),
                  GroupedTile(
                    icon: LucideIcons.languages,
                    title: l10n.language,
                    trailing: Text(_languageName(Localizations.localeOf(context)), style: context.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
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

/// Light or dark, plus the color scheme and background, each with a preview.
class _AppearanceCard extends ConsumerWidget {
  const _AppearanceCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final appearance = ref.watch(appearanceProvider);
    final notifier = ref.read(appearanceProvider.notifier);
    final scheme = context.colorScheme;
    final wallpaper = appearance.wallpaper;
    Widget row({required Key key, required Widget leading, required String title, required String subtitle, required String route}) => InkWell(
      key: key,
      borderRadius: BorderRadius.circular(AppRadius.row),
      onTap: () => context.push(route),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            SizedBox(width: 44, height: 44, child: Center(child: leading)),
            const SizedBox(width: AppSpace.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: context.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            Icon(LucideIcons.chevronRight, size: 20, color: scheme.onSurfaceVariant),
          ],
        ),
      ),
    );
    return AppCard(
      padding: const EdgeInsets.fromLTRB(AppSpace.md, AppSpace.md, AppSpace.sm, AppSpace.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpace.xxs),
            child: AppSegmentedControl<ThemeMode>(
              values: const [ThemeMode.light, ThemeMode.system, ThemeMode.dark],
              labels: {ThemeMode.light: l10n.themeLight, ThemeMode.system: l10n.themeSystem, ThemeMode.dark: l10n.themeDark},
              icons: const {ThemeMode.light: LucideIcons.sun, ThemeMode.system: LucideIcons.sunMoon, ThemeMode.dark: LucideIcons.moon},
              groupValue: appearance.mode,
              onValueChanged: notifier.setMode,
            ),
          ),
          const SizedBox(height: AppSpace.xs),
          row(
            key: const Key('settingsThemes'),
            leading: Icon(LucideIcons.swatchBook, size: 22, color: scheme.primary),
            title: l10n.themes,
            subtitle: [...builtInPresets, ...ref.watch(savedThemesProvider)].where((p) => p.matches(appearance)).firstOrNull?.name ?? l10n.currentLook,
            route: '/settings/themes',
          ),
          Divider(height: 1, indent: 56, color: context.appColors.hairline),
          row(
            key: const Key('settingsTheme'),
            leading: SchemeDots(colors: appearance.scheme.colors(Theme.of(context).brightness), size: 18),
            title: l10n.colorScheme,
            subtitle: appearance.scheme.name,
            route: '/settings/theme',
          ),
          Divider(height: 1, indent: 56, color: context.appColors.hairline),
          row(
            key: const Key('settingsFonts'),
            leading: Text('Aa', style: context.textTheme.titleLarge?.copyWith(color: scheme.primary)),
            title: l10n.fonts,
            subtitle: '${appearance.headingFont} · ${appearance.bodyFont}',
            route: '/settings/fonts',
          ),
          Divider(height: 1, indent: 56, color: context.appColors.hairline),
          row(
            key: const Key('settingsBackground'),
            leading: Container(
              width: 40,
              height: 40,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.appColors.hairline),
              ),
              child: Wallpaper(force: true, specOverride: WallpaperTheme.of(wallpaper.copyWith(everywhere: true), scheme), child: const SizedBox.expand()),
            ),
            title: l10n.background,
            subtitle: [
              wallpaper.pattern.label,
              wallpaper.palette == WallpaperPalette.theme ? l10n.backgroundThemeColors : wallpaper.palette.label,
              if (!wallpaper.everywhere) l10n.chatsOnly,
            ].join(' · '),
            route: '/settings/background',
          ),
        ],
      ),
    );
  }
}

/// Persona, name and autonomy for one bot.
class BotSettingsScreen extends ConsumerStatefulWidget {
  const BotSettingsScreen({super.key, required this.botId});
  final String botId;

  @override
  ConsumerState<BotSettingsScreen> createState() => _BotSettingsScreenState();
}

class _BotSettingsScreenState extends ConsumerState<BotSettingsScreen> {
  TextEditingController? _name;
  TextEditingController? _persona;
  String? _autonomy;
  String? _credentialId;
  String? _model;
  String? _avatar;
  var _avatarLoaded = false;
  var _busy = false;

  @override
  void dispose() {
    _name?.dispose();
    _persona?.dispose();
    super.dispose();
  }

  bool _dirty(Bot bot) =>
      _name!.text.trim() != bot.name ||
      _persona!.text != bot.personaMd ||
      _autonomy != bot.autonomy.value ||
      _credentialId != bot.modelPolicy.primary?.credentialId ||
      _model != bot.modelPolicy.primary?.model ||
      _avatar != bot.avatarUrl;

  Future<void> _save(Bot bot) async {
    final l10n = context.l10n;
    setState(() => _busy = true);
    final modelChanged = _credentialId != bot.modelPolicy.primary?.credentialId || _model != bot.modelPolicy.primary?.model;
    final policy = modelChanged && _credentialId != null && (_model ?? '').isNotEmpty
        ? {
            ...bot.modelPolicy.toJson(),
            'primary': {'credential_id': _credentialId, 'model': _model},
          }
        : null;
    final ok = await runGuarded(context, () async {
      await ref
          .read(backendProvider)
          .updateBot(bot.id, name: _name!.text.trim(), persona: _persona!.text, autonomy: _autonomy, modelPolicy: policy, avatarUrl: _avatar == bot.avatarUrl ? null : (_avatar ?? ''));
      return true;
    });
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok == true) {
      ref.invalidate(botsProvider);
      showMessage(context, l10n.saved);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    final bot = ref.watch(botProvider(widget.botId));
    if (bot == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    _name ??= TextEditingController(text: bot.name);
    _persona ??= TextEditingController(text: bot.personaMd);
    _autonomy ??= bot.autonomy.value;
    _credentialId ??= bot.modelPolicy.primary?.credentialId;
    _model ??= bot.modelPolicy.primary?.model;
    if (!_avatarLoaded) {
      _avatar = bot.avatarUrl;
      _avatarLoaded = true;
    }
    final keys = (ref.watch(credentialsProvider).value ?? const <Credential>[])
        .where((k) => const {ProviderId.openrouter, ProviderId.openai, ProviderId.anthropic, ProviderId.google, ProviderId.xai, ProviderId.openaiCompatible}.contains(k.provider))
        .toList();
    final computers = ref.watch(computersProvider).value ?? const <Computer>[];
    final usable = computers.where((c) => c.kind == ComputerKindEnum.team || c.kind == ComputerKindEnum.local || c.ownerBotId == bot.id).toList();
    final dirty = _dirty(bot);
    final name = _name!.text.trim().isEmpty ? bot.name : _name!.text.trim();
    final levels = [
      ('ask_always', LucideIcons.hand, l10n.autonomyAskAlways, l10n.autonomyAskAlwaysHelp),
      ('ask_risky', LucideIcons.shield, l10n.autonomyAskRisky, l10n.autonomyAskRiskyHelp),
      ('autonomous', LucideIcons.zap, l10n.autonomyAutonomous, l10n.autonomyAutonomousHelp),
    ];
    return SubPage(
      title: l10n.botSettings,
      subtitle: bot.name,
      actions: [
        if (dirty)
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: GlowButton(onPressed: _busy ? null : () => _save(bot), child: Text(l10n.save)),
          ),
      ],
      children: [
        AppCard(
          padding: const EdgeInsets.all(AppSpace.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: AppSpace.md,
            children: [
              Row(
                children: [
                  BotAvatar(name: name, avatar: _avatar, size: 64, status: bot.status),
                  const SizedBox(width: AppSpace.md),
                  Expanded(
                    child: TextField(
                      controller: _name,
                      decoration: InputDecoration(labelText: l10n.botName),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: AppSpace.sm,
                children: [
                  Text(l10n.botIcon, style: context.textTheme.labelLarge?.copyWith(color: scheme.onSurfaceVariant)),
                  MascotPicker(value: _avatar, initials: botInitials(name), initialsLabel: l10n.botIconInitials, onChanged: (v) => setState(() => _avatar = v)),
                ],
              ),
              TextField(
                controller: _persona,
                decoration: InputDecoration(labelText: l10n.persona, hintText: l10n.personaHint, alignLabelWithHint: true),
                maxLines: 12,
                minLines: 4,
                onChanged: (_) => setState(() {}),
              ),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton.icon(
                  key: const Key('loadPersona'),
                  icon: const Icon(LucideIcons.swatchBook, size: 18),
                  label: Text(l10n.loadPersona),
                  onPressed: () async {
                    final choice = await showPersonaGallery(context, allowBlank: false);
                    final t = choice?.template;
                    if (t == null || !context.mounted) return;
                    if (_persona!.text.trim().isNotEmpty) {
                      final ok = await showConfirm(context: context, title: l10n.replaceInstructionsTitle, message: l10n.replaceInstructionsBody(t.name), confirmLabel: l10n.replace);
                      if (!ok) return;
                    }
                    setState(() => _persona!.text = t.persona ?? '');
                  },
                ),
              ),
            ],
          ),
        ),
        SectionHeader(title: l10n.thinking0),
        AppCard(
          padding: const EdgeInsets.all(AppSpace.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: AppSpace.md,
            children: [
              DropdownButtonFormField<String>(
                isExpanded: true,
                key: ValueKey('botKey-${keys.length}'),
                initialValue: keys.any((k) => k.id == _credentialId) ? _credentialId : null,
                decoration: InputDecoration(labelText: l10n.modelKey, prefixIcon: const Icon(LucideIcons.keyRound, size: 20)),
                items: [for (final k in keys) DropdownMenuItem(value: k.id, child: Text('${k.label} · ${providerLabel(k.provider)}', maxLines: 1, overflow: TextOverflow.ellipsis))],
                onChanged: (v) => setState(() {
                  _credentialId = v;
                  for (final k in keys) {
                    if (k.id == v) _model = ref.read(backendProvider).defaultModelFor(k.provider.value) ?? _model;
                  }
                }),
              ),
              ModelPickerField(credentialId: _credentialId, value: _model ?? '', onChanged: (m) => setState(() => _model = m)),
            ],
          ),
        ),
        SectionHeader(title: l10n.autonomy),
        RadioGroup<String>(
          groupValue: _autonomy,
          onChanged: (v) => setState(() => _autonomy = v),
          child: Column(
            spacing: AppSpace.xs,
            children: [
              for (final (value, icon, title, help) in levels)
                AppCard(
                  key: Key('autonomy-$value'),
                  onTap: () => setState(() => _autonomy = value),
                  padding: const EdgeInsets.fromLTRB(AppSpace.md, 14, AppSpace.sm, 14),
                  borderColor: _autonomy == value ? scheme.primary : null,
                  borderWidth: _autonomy == value ? 1.5 : 1,
                  color: _autonomy == value ? Color.alphaBlend(scheme.primary.withValues(alpha: 0.06), scheme.surfaceContainerLow) : null,
                  child: Row(
                    children: [
                      Icon(icon, color: _autonomy == value ? scheme.primary : scheme.onSurfaceVariant),
                      const SizedBox(width: AppSpace.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title, style: context.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700)),
                            Text(help, style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant, height: 1.35)),
                          ],
                        ),
                      ),
                      Radio<String>(value: value),
                    ],
                  ),
                ),
            ],
          ),
        ),
        SectionHeader(title: l10n.computerAndTools),
        GroupedCard(
          children: [
            Builder(
              builder: (context) {
                final current = usable.where((c) => c.id == bot.defaultComputerId).firstOrNull;
                return GroupedTile(
                  key: const Key('botComputer'),
                  icon: LucideIcons.monitor,
                  title: l10n.botComputer,
                  subtitle: current?.name ?? l10n.botComputerAuto,
                  trailing: Icon(LucideIcons.chevronsUpDown, color: scheme.onSurfaceVariant),
                  onTap: () async {
                    final picked = await showChoiceSheet<String?>(
                      context,
                      title: l10n.botComputer,
                      subtitle: l10n.botComputerHelp,
                      icon: LucideIcons.monitor,
                      selected: current?.id,
                      choices: [
                        Choice(value: null, label: l10n.botComputerAuto, subtitle: l10n.botComputerDefault, icon: LucideIcons.wandSparkles),
                        for (final c in usable)
                          Choice(
                            value: c.id,
                            label: c.name,
                            subtitle: [
                              if ((c.kind == ComputerKindEnum.team ? l10n.teamComputer : l10n.privateComputer) != c.name) c.kind == ComputerKindEnum.team ? l10n.teamComputer : l10n.privateComputer,
                              c.profile == ComputerProfileEnum.desktop ? l10n.profileDesktop : l10n.profileHeadless,
                            ].join(' · '),
                            icon: c.profile == ComputerProfileEnum.desktop ? LucideIcons.monitor : LucideIcons.squareTerminal,
                          ),
                      ],
                    );
                    if (picked == null || !context.mounted) return;
                    await runGuarded(context, () => ref.read(backendProvider).setBotComputer(bot.id, picked.value));
                    ref.invalidate(botsProvider);
                  },
                );
              },
            ),
            GroupedTile(
              key: const Key('botVoice'),
              icon: LucideIcons.speech,
              title: l10n.voiceSettings,
              subtitle: l10n.voiceSettingsHelp,
              onTap: () => showAdaptiveSheet<void>(
                context: context,
                builder: (_) => VoiceSettingsDialog(botId: bot.id),
              ),
            ),
            GroupedTile(icon: LucideIcons.clock, title: l10n.routines, onTap: () => context.push('/bots/${bot.id}/routines')),
            GroupedTile(icon: LucideIcons.puzzle, title: l10n.botIntegrations, onTap: () => context.push('/bots/${bot.id}/integrations')),
            GroupedTile(icon: LucideIcons.brain, title: l10n.memory, onTap: () => context.push('/bots/${bot.id}/memory')),
          ],
        ),
        const SizedBox(height: AppSpace.md),
        GroupedCard(
          children: [
            Builder(
              builder: (context) {
                final folders = ref.watch(botFoldersProvider).value ?? const <BotFolder>[];
                final current = folders.where((f) => f.id == bot.folderId).firstOrNull;
                return GroupedTile(
                  key: const Key('botFolder'),
                  icon: LucideIcons.folder,
                  title: l10n.botFolder,
                  subtitle: current?.name ?? l10n.noFolder,
                  trailing: Icon(LucideIcons.chevronsUpDown, color: scheme.onSurfaceVariant),
                  onTap: () async {
                    const fresh = '\u0000new';
                    final picked = await showChoiceSheet<String?>(
                      context,
                      title: l10n.botFolder,
                      icon: LucideIcons.folder,
                      selected: current?.name,
                      choices: [
                        Choice(value: null, label: l10n.noFolder, icon: LucideIcons.folderMinus),
                        for (final f in folders) Choice(value: f.name, label: f.name, icon: LucideIcons.folder),
                        Choice(value: fresh, label: l10n.newFolder, icon: LucideIcons.folderPlus),
                      ],
                    );
                    if (picked == null || !context.mounted) return;
                    var name = picked.value;
                    if (name == fresh) {
                      name = (await showTextPrompt(context, title: l10n.newFolder, label: l10n.folderName, submitLabel: l10n.save, fieldKey: const Key('folderName')))?.trim();
                      if (name == null || name.isEmpty || !context.mounted) return;
                    }
                    final org = ref.read(currentOrgProvider);
                    if (org == null) return;
                    await runGuarded(context, () => ref.read(backendProvider).setBotFolder(org.id, bot.id, name));
                    ref
                      ..invalidate(botsProvider)
                      ..invalidate(botFoldersProvider);
                  },
                );
              },
            ),
            GroupedTile(key: const Key('botSharing'), icon: LucideIcons.users, title: l10n.sharing, subtitle: l10n.sharingRow, onTap: () => context.push('/bots/${bot.id}/sharing')),
            GroupedTile(key: const Key('botReplays'), icon: LucideIcons.listVideo, title: l10n.replays, subtitle: l10n.replaysRow, onTap: () => context.push('/bots/${bot.id}/replays')),
            GroupedTile(key: const Key('botChatApps'), icon: LucideIcons.messagesSquare, title: l10n.chatApps, subtitle: l10n.chatAppsRow, onTap: () => context.push('/bots/${bot.id}/chat-apps')),
            GroupedTile(key: const Key('botLinks'), icon: LucideIcons.link, title: l10n.links, subtitle: l10n.linksRow, onTap: () => context.push('/bots/${bot.id}/links')),
            GroupedTile(
              key: const Key('botA2a'),
              icon: LucideIcons.bot,
              title: l10n.a2aPublish,
              subtitle: l10n.a2aPublishHelp,
              onTap: () => showAdaptiveSheet<void>(
                context: context,
                builder: (_) => BotA2aSheet(botId: bot.id),
              ),
            ),
            GroupedTile(key: const Key('botKnowledge'), icon: LucideIcons.library, title: l10n.knowledge, subtitle: l10n.knowledgeRow, onTap: () => context.push('/bots/${bot.id}/knowledge')),
            GroupedTile(key: const Key('botPlugins'), icon: LucideIcons.puzzle, title: l10n.plugins, subtitle: l10n.pluginsRow, onTap: () => context.push('/bots/${bot.id}/plugins')),
            GroupedTile(key: const Key('botPages'), icon: LucideIcons.fileText, title: l10n.pages, subtitle: l10n.pagesRow, onTap: () => context.push('/pages?bot=${bot.id}')),
            GroupedTile(key: const Key('botWatchers'), icon: LucideIcons.eye, title: l10n.watchers, subtitle: l10n.watchersRow, onTap: () => context.push('/bots/${bot.id}/watchers')),
            GroupedTile(key: const Key('botRules'), icon: LucideIcons.shieldCheck, title: l10n.actionRules, subtitle: l10n.actionRulesRow, onTap: () => context.push('/bots/${bot.id}/rules')),
            GroupedTile(
              key: const Key('botCheckins'),
              icon: LucideIcons.sun,
              title: l10n.checkins,
              subtitle: ref.watch(botCheckinsProvider(bot.id)).value?.enabled == true ? l10n.on : l10n.off,
              onTap: () => showCheckins(context, ref, bot.id),
            ),
            GroupedTile(
              key: const Key('botQuiet'),
              icon: LucideIcons.bellRing,
              title: l10n.botNotifications,
              subtitle: switch (ref.watch(botQuietProvider(bot.id)).value?.mode) {
                'always' => l10n.quietAlways,
                'custom' => l10n.quietCustom,
                _ => l10n.quietDefault,
              },
              onTap: () => showBotQuiet(context, ref, bot.id),
            ),
            GroupedTile(
              key: const Key('rerunSetup'),
              icon: LucideIcons.sparkles,
              title: l10n.rerunSetup,
              subtitle: l10n.rerunSetupHelp,
              onTap: () async {
                final conv = await runGuarded(context, () => ref.read(backendProvider).startBotSetup(bot.id));
                if (conv == null || !context.mounted) return;
                ref.invalidate(botsProvider);
                GoRouter.maybeOf(context)?.go('/bots/${bot.id}/chat?c=$conv');
              },
            ),
            GroupedTile(key: const Key('shareBot'), icon: LucideIcons.share2, title: l10n.shareAsTemplate, subtitle: l10n.shareAsTemplateRow, onTap: () => showShareBot(context, bot)),
            GroupedTile(key: const Key('botHistory'), icon: LucideIcons.history, title: l10n.settingsHistory, subtitle: l10n.settingsHistoryHelp, onTap: () => context.push('/bots/${bot.id}/history')),
            GroupedTile(
              key: const Key('archiveBot'),
              icon: LucideIcons.archive,
              title: l10n.archiveBot,
              onTap: () async {
                final ok = await showConfirm(
                  context: context,
                  title: l10n.archiveBotTitle(bot.name),
                  message: l10n.archiveBotBody,
                  confirmLabel: l10n.archive,
                  destructive: true,
                  icon: LucideIcons.archive,
                  confirmKey: const Key('confirmArchive'),
                );
                if (!ok || !context.mounted) return;
                final done = await runGuarded(context, () async {
                  await ref.read(backendProvider).setBotArchived(bot.id, true);
                  return true;
                });
                if (done != true || !context.mounted) return;
                ref
                  ..invalidate(botsProvider)
                  ..invalidate(archivedBotsProvider);
                showMessage(context, l10n.botArchived(bot.name));
                GoRouter.maybeOf(context)?.go('/bots');
              },
            ),
          ],
        ),
        const SizedBox(height: AppSpace.lg),
        GlowButton.icon(
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
          onPressed: _busy || !dirty ? null : () => _save(bot),
          icon: const Icon(LucideIcons.check, size: 20),
          label: Text(l10n.saveChanges),
        ),
      ],
    );
  }
}

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
    String label(String p) => switch (p) {
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
        DropdownButtonFormField<String?>(
          isExpanded: true,
          key: const Key('ttsProvider'),
          initialValue: _tts,
          decoration: InputDecoration(labelText: l10n.readAloudProvider, prefixIcon: const Icon(LucideIcons.volume2, size: 20)),
          items: [
            DropdownMenuItem(value: null, child: Text(l10n.automatic)),
            for (final p in const ['elevenlabs', 'openai', 'cartesia', 'fish_audio']) DropdownMenuItem(value: p, child: Text(label(p))),
          ],
          onChanged: (v) => setState(() => _tts = v),
        ),
        TextField(
          controller: _voice,
          decoration: InputDecoration(labelText: l10n.voiceId, helperText: l10n.voiceIdHelp, prefixIcon: const Icon(LucideIcons.audioLines, size: 20)),
        ),
        DropdownButtonFormField<String?>(
          isExpanded: true,
          key: const Key('sttProvider'),
          initialValue: _stt,
          decoration: InputDecoration(labelText: l10n.dictationProvider, prefixIcon: const Icon(LucideIcons.mic, size: 20)),
          items: [
            DropdownMenuItem(value: null, child: Text(l10n.automatic)),
            for (final p in const ['openai', 'deepgram']) DropdownMenuItem(value: p, child: Text(label(p))),
          ],
          onChanged: (v) => setState(() => _stt = v),
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
            onChanged: (v) async {
              await runGuarded(context, () => setAutoUpdateChecks(v));
              ref.invalidate(autoUpdateChecksProvider);
            },
          ),
      ],
    );
  }
}

