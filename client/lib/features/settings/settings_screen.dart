import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kasama_sdk/kasama_sdk.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/billing.dart';
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
import '../bots/template_picker.dart';
import '../../ui/mascot.dart';
import '../../ui/page.dart';
import '../bots/model_picker.dart';
import 'model_keys_screen.dart';
import 'theme_screen.dart';
import '../../ui/app_card.dart';
import '../../ui/segmented.dart';
import '../../ui/shell_header.dart';
import '../admin/admin_screen.dart';
import '../companion/companion.dart';
import '../../ui/glow_button.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _invite(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final email = await showTextPrompt(
      context,
      title: l10n.inviteMember,
      subtitle: l10n.inviteMemberHelp,
      label: l10n.email,
      hint: 'name@company.com',
      submitLabel: l10n.sendInvite,
      icon: LucideIcons.userPlus,
      fieldIcon: LucideIcons.atSign,
      keyboardType: TextInputType.emailAddress,
    );
    if (email == null || email.isEmpty || !context.mounted) return;
    final org = ref.read(currentOrgProvider)!;
    final invite = await runGuarded(context, () => ref.read(backendProvider).invite(org.id, email));
    if (invite == null || !context.mounted) return;
    if (invite.acceptToken != null) {
      await showAdaptiveSheet<void>(
        context: context,
        builder: (_) => _InviteCode(email: email, code: invite.acceptToken!),
      );
    } else {
      showMessage(context, l10n.inviteSent(email));
    }
  }

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
    return Scaffold(
      appBar: ShellHeader(title: l10n.settings),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final side = AppSpace.gutter + AppBreakpoints.centeringInset(constraints.maxWidth, maxWidth: kPageMaxWidth);
          return ListView(
            padding: EdgeInsets.fromLTRB(side, AppSpace.xs, side, AppSpace.xxl + MediaQuery.paddingOf(context).bottom),
            children: [
              AppCard(
                padding: const EdgeInsets.all(AppSpace.md),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(color: scheme.primary.withValues(alpha: 0.16), shape: BoxShape.circle),
                      alignment: Alignment.center,
                      child: Text(
                        email.isEmpty ? '?' : email.characters.first.toUpperCase(),
                        style: context.textTheme.titleLarge?.copyWith(color: scheme.primary, fontWeight: FontWeight.w800),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            email,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            [org?.name ?? '', if (org != null) _roleLabel(context, org.role)].where((s) => s.isNotEmpty).join(' · '),
                            style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ).appCardEntrance(),
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
                  if (isAdmin) GroupedTile(icon: LucideIcons.userPlus, title: l10n.inviteMember, onTap: () => _invite(context, ref)),
                  GroupedTile(
                    key: const Key('settingsUsage'),
                    icon: LucideIcons.banknote,
                    iconColor: colors.positive,
                    onTap: () => context.push('/settings/usage'),
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
                      onTap: () => context.push('/settings/billing'),
                    ),
                ],
              ),
              SectionHeader(title: l10n.settingsBotsSection),
              GroupedCard(
                children: [
                  GroupedTile(icon: LucideIcons.keyRound, title: l10n.modelKeys, subtitle: l10n.modelKeysHelp, onTap: () => context.push('/settings/keys')),
                  GroupedTile(icon: LucideIcons.bookOpen, title: l10n.skills, subtitle: l10n.skillsRowHelp, onTap: () => context.push('/settings/skills')),
                  GroupedTile(
                    key: const Key('settingsIntegrations'),
                    icon: LucideIcons.puzzle,
                    title: l10n.integrations,
                    subtitle: l10n.integrationsRowHelp,
                    onTap: () => context.push('/settings/integrations'),
                  ),
                  GroupedTile(
                    key: const Key('settingsSecrets'),
                    icon: LucideIcons.lock,
                    title: l10n.secrets,
                    subtitle: l10n.secretsRowHelp,
                    onTap: () => context.push('/settings/secrets'),
                  ),
                  GroupedTile(
                    key: const Key('settingsComputers'),
                    icon: LucideIcons.monitor,
                    title: l10n.computers,
                    subtitle: l10n.computersRowHelp,
                    onTap: () => context.push('/settings/computers'),
                  ),
                  if (ref.watch(companionProvider).supported)
                    GroupedTile(
                      key: const Key('settingsCompanion'),
                      icon: LucideIcons.laptop,
                      title: l10n.useThisComputer,
                      subtitle: l10n.companionRowHelp,
                      onTap: () => context.push('/settings/companion'),
                    ),
                ],
              ),
              SectionHeader(title: l10n.appearance),
              const _AppearanceCard(),
              SectionHeader(title: l10n.settingsMoreSection),
              GroupedCard(
                children: [
                  GroupedTile(
                    key: const Key('settingsTwoStep'),
                    icon: LucideIcons.smartphone,
                    title: l10n.twoStepSignIn,
                    subtitle: org?.requireMfa == true && org?.role != OrgRole.member && !backend.twoStepVerified
                        ? l10n.twoStepNeededForAdmin
                        : l10n.twoStepHelp,
                    onTap: () => context.push('/settings/two-step'),
                  ),
                  GroupedTile(
                    key: const Key('settingsPrivacy'),
                    icon: LucideIcons.shieldCheck,
                    title: l10n.privacy,
                    subtitle: l10n.privacyRowHelp,
                    onTap: () => context.push('/settings/privacy'),
                  ),
                  if (ref.watch(adminOverviewProvider).value != null)
                    GroupedTile(
                      key: const Key('settingsAdmin'),
                      icon: LucideIcons.shieldUser,
                      title: l10n.adminConsole,
                      subtitle: l10n.adminRowHelp,
                      onTap: () => context.push('/settings/admin'),
                    ),
                  GroupedTile(
                    icon: LucideIcons.languages,
                    title: l10n.language,
                    trailing: Text(
                      _languageName(Localizations.localeOf(context)),
                      style: context.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                    ),
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
                      final ok = await showConfirm(
                        context: context,
                        title: l10n.signOut,
                        message: l10n.signOutConfirm,
                        confirmLabel: l10n.signOut,
                        destructive: true,
                      );
                      if (ok && context.mounted) await runGuarded(context, backend.signOut);
                    },
                  ),
                ],
              ),
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
      await ref.read(backendProvider).updateBot(
        bot.id,
        name: _name!.text.trim(),
        persona: _persona!.text,
        autonomy: _autonomy,
        modelPolicy: policy,
        avatarUrl: _avatar == bot.avatarUrl ? null : (_avatar ?? ''),
      );
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
        .where(
          (k) => const {
            ProviderId.openrouter,
            ProviderId.openai,
            ProviderId.anthropic,
            ProviderId.google,
            ProviderId.xai,
            ProviderId.openaiCompatible,
          }.contains(k.provider),
        )
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
                  MascotPicker(
                    value: _avatar,
                    initials: botInitials(name),
                    initialsLabel: l10n.botIconInitials,
                    onChanged: (v) => setState(() => _avatar = v),
                  ),
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
                      final ok = await showConfirm(
                        context: context,
                        title: l10n.replaceInstructionsTitle,
                        message: l10n.replaceInstructionsBody(t.name),
                        confirmLabel: l10n.replace,
                      );
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
                key: ValueKey('botKey-${keys.length}'),
                initialValue: keys.any((k) => k.id == _credentialId) ? _credentialId : null,
                decoration: InputDecoration(labelText: l10n.modelKey, prefixIcon: const Icon(LucideIcons.keyRound, size: 20)),
                items: [for (final k in keys) DropdownMenuItem(value: k.id, child: Text('${k.label} · ${providerLabel(k.provider)}'))],
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
                              if ((c.kind == ComputerKindEnum.team ? l10n.teamComputer : l10n.privateComputer) != c.name)
                                c.kind == ComputerKindEnum.team ? l10n.teamComputer : l10n.privateComputer,
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

class _InviteCode extends StatelessWidget {
  const _InviteCode({required this.email, required this.code});
  final String email;
  final String code;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return FormSheet(
      icon: LucideIcons.mailCheck,
      title: l10n.inviteReady,
      subtitle: l10n.inviteCodeHelp(email),
      submitLabel: l10n.copyCode,
      submitIcon: LucideIcons.copy,
      cancelLabel: l10n.close,
      onSubmit: () {
        Clipboard.setData(ClipboardData(text: code));
        Navigator.pop(context);
        showMessage(context, l10n.copied);
      },
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: 14),
          decoration: BoxDecoration(
            color: context.appColors.codeBackground,
            borderRadius: AppRadius.tileAll,
            border: Border.all(color: context.appColors.hairline),
          ),
          child: SelectableText(code, style: AppText.mono.copyWith(fontSize: 15, fontWeight: FontWeight.w600)),
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

  @override
  void dispose() {
    _voice.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    final ok = await runGuarded(context, () async {
      await ref.read(backendProvider).updateBotVoice(widget.botId, {
        'tts_provider': ?_tts,
        'stt_provider': ?_stt,
        if (_voice.text.trim().isNotEmpty) 'tts_voice': _voice.text.trim(),
      });
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
          key: const Key('sttProvider'),
          initialValue: _stt,
          decoration: InputDecoration(labelText: l10n.dictationProvider, prefixIcon: const Icon(LucideIcons.mic, size: 20)),
          items: [
            DropdownMenuItem(value: null, child: Text(l10n.automatic)),
            for (final p in const ['openai', 'deepgram']) DropdownMenuItem(value: p, child: Text(label(p))),
          ],
          onChanged: (v) => setState(() => _stt = v),
        ),
      ],
    );
  }
}
