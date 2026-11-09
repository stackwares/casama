import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kasama_sdk/kasama_sdk.dart';

import '../../core/billing.dart';
import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_tokens.dart';
import '../../theme/appearance.dart';
import '../../ui/adaptive_modal.dart';
import '../../ui/app_card.dart';
import '../../ui/segmented.dart';
import '../../ui/shell_header.dart';
import '../admin/admin_screen.dart';
import '../companion/companion.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _invite(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final controller = TextEditingController();
    final email = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(l10n.inviteMember),
        content: TextField(controller: controller, decoration: InputDecoration(labelText: l10n.email), autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: Text(l10n.cancel)),
          FilledButton(onPressed: () => Navigator.pop(c, controller.text.trim()), child: Text(l10n.inviteMember)),
        ],
      ),
    );
    controller.dispose();
    if (email == null || email.isEmpty || !context.mounted) return;
    final org = ref.read(currentOrgProvider)!;
    final invite = await runGuarded(context, () => ref.read(backendProvider).invite(org.id, email));
    if (invite == null || !context.mounted) return;
    if (invite.acceptToken != null) {
      await showDialog<void>(
        context: context,
        builder: (c) => AlertDialog(
          content: SelectableText(l10n.inviteCodeToShare(invite.acceptToken!)),
          actions: [TextButton(onPressed: () => Navigator.pop(c), child: Text(l10n.close))],
        ),
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
      body: LayoutBuilder(builder: (context, constraints) {
        final side = AppSpace.gutter + AppBreakpoints.centeringInset(constraints.maxWidth, maxWidth: 640);
        return ListView(
          padding: EdgeInsets.fromLTRB(side, AppSpace.xs, side, AppSpace.xxl + MediaQuery.paddingOf(context).bottom),
          children: [
            AppCard(
              padding: const EdgeInsets.all(AppSpace.md),
              child: Row(children: [
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
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(email, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(
                      [org?.name ?? '', if (org != null) _roleLabel(context, org.role)].where((s) => s.isNotEmpty).join(' · '),
                      style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ]),
                ),
              ]),
            ).appCardEntrance(),
            SectionHeader(title: l10n.workspace),
            GroupedCard(children: [
              GroupedTile(
                icon: Icons.workspaces_outline,
                title: org?.name ?? l10n.workspace,
                subtitle: orgs.length > 1 ? l10n.switchWorkspace : null,
                trailing: orgs.length > 1
                    ? PopupMenuButton<String>(
                        tooltip: l10n.switchWorkspace,
                        icon: Icon(Icons.unfold_more_rounded, color: scheme.onSurfaceVariant),
                        onSelected: (id) => ref.read(selectedOrgIdProvider.notifier).select(id),
                        itemBuilder: (_) => [for (final o in orgs) PopupMenuItem(value: o.id, child: Text(o.name))],
                      )
                    : null,
              ),
              if (isAdmin) GroupedTile(icon: Icons.person_add_alt_1_outlined, title: l10n.inviteMember, onTap: () => _invite(context, ref)),
              GroupedTile(
                icon: Icons.payments_outlined,
                iconColor: colors.positive,
                title: l10n.usage,
                trailing: Text(
                  formatUsd(month?.totalCostUsd ?? 0),
                  style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700, fontFeatures: AppText.tabular),
                ),
                subtitle: l10n.usageMonth(formatUsd(month?.totalCostUsd ?? 0)),
              ),
              if (billing?.enabled ?? false)
                GroupedTile(
                  key: const Key('settingsBilling'),
                  icon: Icons.workspace_premium_outlined,
                  iconColor: colors.warning,
                  title: l10n.billing,
                  subtitle: billing!.planName,
                  onTap: () => context.push('/settings/billing'),
                ),
            ]),
            SectionHeader(title: l10n.settingsBotsSection),
            GroupedCard(children: [
              GroupedTile(icon: Icons.key_outlined, title: l10n.modelKeys, subtitle: l10n.modelKeysHelp, onTap: () => context.push('/settings/keys')),
              GroupedTile(icon: Icons.menu_book_outlined, title: l10n.skills, onTap: () => context.push('/settings/skills')),
              GroupedTile(
                key: const Key('settingsIntegrations'),
                icon: Icons.extension_outlined,
                title: l10n.integrations,
                onTap: () => context.push('/settings/integrations'),
              ),
              GroupedTile(key: const Key('settingsSecrets'), icon: Icons.lock_outline_rounded, title: l10n.secrets, onTap: () => context.push('/settings/secrets')),
              GroupedTile(
                key: const Key('settingsComputers'),
                icon: Icons.desktop_windows_outlined,
                title: l10n.computers,
                onTap: () => context.push('/settings/computers'),
              ),
              if (ref.watch(companionProvider).supported)
                GroupedTile(
                  key: const Key('settingsCompanion'),
                  icon: Icons.laptop_mac_rounded,
                  title: l10n.useThisComputer,
                  onTap: () => context.push('/settings/companion'),
                ),
            ]),
            SectionHeader(title: l10n.appearance),
            const _AppearanceCard(),
            SectionHeader(title: l10n.settingsMoreSection),
            GroupedCard(children: [
              GroupedTile(
                key: const Key('settingsPrivacy'),
                icon: Icons.privacy_tip_outlined,
                title: l10n.privacy,
                onTap: () => context.push('/settings/privacy'),
              ),
              if (ref.watch(adminOverviewProvider).value != null)
                GroupedTile(
                  key: const Key('settingsAdmin'),
                  icon: Icons.admin_panel_settings_outlined,
                  title: l10n.adminConsole,
                  onTap: () => context.push('/settings/admin'),
                ),
              GroupedTile(
                icon: Icons.translate_rounded,
                title: l10n.language,
                trailing: Text(
                  Localizations.localeOf(context).toLanguageTag(),
                  style: context.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ),
            ]),
            const SizedBox(height: AppSpace.lg),
            GroupedCard(children: [
              GroupedTile(
                icon: Icons.logout_rounded,
                title: l10n.signOut,
                destructive: true,
                showChevron: false,
                onTap: () async {
                  final ok = await showConfirm(context: context, title: l10n.signOut, message: l10n.signOutConfirm, confirmLabel: l10n.signOut, destructive: true);
                  if (ok && context.mounted) await runGuarded(context, backend.signOut);
                },
              ),
            ]),
          ],
        );
      }),
    );
  }
}

String _roleLabel(BuildContext context, OrgRole role) => switch (role) {
      OrgRole.owner => context.l10n.roleOwner,
      OrgRole.admin => context.l10n.roleAdmin,
      _ => context.l10n.roleMember,
    };

/// Theme mode and accent color, kept on this device.
class _AppearanceCard extends ConsumerWidget {
  const _AppearanceCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final appearance = ref.watch(appearanceProvider);
    final notifier = ref.read(appearanceProvider.notifier);
    final scheme = context.colorScheme;
    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        AppSegmentedControl<ThemeMode>(
          values: const [ThemeMode.light, ThemeMode.system, ThemeMode.dark],
          labels: {ThemeMode.light: l10n.themeLight, ThemeMode.system: l10n.themeSystem, ThemeMode.dark: l10n.themeDark},
          icons: const {ThemeMode.light: Icons.light_mode_outlined, ThemeMode.system: Icons.brightness_auto_outlined, ThemeMode.dark: Icons.dark_mode_outlined},
          groupValue: appearance.mode,
          onValueChanged: notifier.setMode,
        ),
        const SizedBox(height: AppSpace.md),
        Text(l10n.accentColor, style: context.textTheme.labelLarge?.copyWith(color: scheme.onSurfaceVariant)),
        const SizedBox(height: AppSpace.sm),
        Wrap(spacing: 12, runSpacing: 12, children: [
          for (final a in AppAccent.values)
            Tooltip(
              message: a.label,
              excludeFromSemantics: true,
              child: Semantics(
                button: true,
                selected: a == appearance.accent,
                label: a.label,
                child: InkResponse(
                  key: Key('accent-${a.name}'),
                  onTap: () => notifier.setAccent(a),
                  radius: 22,
                  child: AnimatedContainer(
                    duration: AppMotion.of(context, AppMotion.fast),
                    width: 36,
                    height: 36,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: a == appearance.accent ? a.seed : Colors.transparent, width: 2),
                    ),
                    child: DecoratedBox(
                      decoration: BoxDecoration(color: a.seed, shape: BoxShape.circle),
                      child: a == appearance.accent ? const Icon(Icons.check_rounded, size: 16, color: Colors.white) : null,
                    ),
                  ),
                ),
              ),
            ),
        ]),
      ]),
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

  @override
  void dispose() {
    _name?.dispose();
    _persona?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bot = ref.watch(botProvider(widget.botId));
    if (bot == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    _name ??= TextEditingController(text: bot.name);
    _persona ??= TextEditingController(text: bot.personaMd);
    _autonomy ??= bot.autonomy.value;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.botSettings)),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        TextField(controller: _name, decoration: InputDecoration(labelText: l10n.botName)),
        const SizedBox(height: 12),
        TextField(controller: _persona, decoration: InputDecoration(labelText: l10n.persona), maxLines: 6, minLines: 3),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _autonomy,
          decoration: InputDecoration(labelText: l10n.autonomy),
          items: [
            DropdownMenuItem(value: 'ask_always', child: Text(l10n.autonomyAskAlways)),
            DropdownMenuItem(value: 'ask_risky', child: Text(l10n.autonomyAskRisky)),
            DropdownMenuItem(value: 'autonomous', child: Text(l10n.autonomyAutonomous)),
          ],
          onChanged: (v) => setState(() => _autonomy = v),
        ),
        const SizedBox(height: 8),
        ListTile(
          key: const Key('botVoice'),
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.record_voice_over_outlined),
          title: Text(l10n.voiceSettings),
          subtitle: Text(l10n.voiceSettingsHelp),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => showDialog<void>(context: context, builder: (_) => VoiceSettingsDialog(botId: bot.id)),
        ),
        Builder(builder: (context) {
          final computers = ref.watch(computersProvider).value ?? const <Computer>[];
          final usable = computers
              .where((c) => c.kind == ComputerKindEnum.team || c.kind == ComputerKindEnum.local || c.ownerBotId == bot.id)
              .toList();
          return DropdownButtonFormField<String?>(
            key: const Key('botComputer'),
            initialValue: usable.any((c) => c.id == bot.defaultComputerId) ? bot.defaultComputerId : null,
            decoration: InputDecoration(labelText: l10n.botComputer),
            items: [
              DropdownMenuItem<String?>(value: null, child: Text(l10n.botComputerDefault)),
              for (final c in usable) DropdownMenuItem<String?>(value: c.id, child: Text(c.name)),
            ],
            onChanged: (v) async {
              await runGuarded(context, () => ref.read(backendProvider).setBotComputer(bot.id, v));
              ref.invalidate(botsProvider);
            },
          );
        }),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.schedule),
          title: Text(l10n.routines),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push('/bots/${bot.id}/routines'),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.extension_outlined),
          title: Text(l10n.botIntegrations),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push('/bots/${bot.id}/integrations'),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.model),
          subtitle: Text(bot.modelPolicy.primary?.model ?? '—'),
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: () async {
            final ok = await runGuarded(context, () async {
              await ref.read(backendProvider).updateBot(
                    bot.id,
                    name: _name!.text.trim(),
                    persona: _persona!.text,
                    autonomy: _autonomy,
                  );
              return true;
            });
            if (ok == true && context.mounted) {
              ref.invalidate(botsProvider);
              showMessage(context, l10n.saved);
            }
          },
          child: Text(l10n.save),
        ),
      ]),
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

  @override
  void dispose() {
    _voice.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.voiceSettings),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        DropdownButtonFormField<String?>(
          key: const Key('ttsProvider'),
          initialValue: _tts,
          decoration: InputDecoration(labelText: l10n.readAloudProvider),
          items: [
            DropdownMenuItem(value: null, child: Text(l10n.automatic)),
            for (final p in const ['elevenlabs', 'openai', 'cartesia', 'fish_audio']) DropdownMenuItem(value: p, child: Text(p)),
          ],
          onChanged: (v) => setState(() => _tts = v),
        ),
        TextField(controller: _voice, decoration: InputDecoration(labelText: l10n.voiceId, helperText: l10n.voiceIdHelp)),
        DropdownButtonFormField<String?>(
          key: const Key('sttProvider'),
          initialValue: _stt,
          decoration: InputDecoration(labelText: l10n.dictationProvider),
          items: [
            DropdownMenuItem(value: null, child: Text(l10n.automatic)),
            for (final p in const ['openai', 'deepgram']) DropdownMenuItem(value: p, child: Text(p)),
          ],
          onChanged: (v) => setState(() => _stt = v),
        ),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
        FilledButton(
          key: const Key('saveVoice'),
          onPressed: () async {
            final ok = await runGuarded(context, () async {
              await ref.read(backendProvider).updateBotVoice(widget.botId, {
                'tts_provider': ?_tts,
                'stt_provider': ?_stt,
                if (_voice.text.trim().isNotEmpty) 'tts_voice': _voice.text.trim(),
              });
              return true;
            });
            if (ok == true && context.mounted) Navigator.pop(context);
          },
          child: Text(l10n.save),
        ),
      ],
    );
  }
}
