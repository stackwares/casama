import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kasama_sdk/kasama_sdk.dart';

import '../../core/billing.dart';
import '../../core/providers.dart';
import '../../core/widgets.dart';
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
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListView(children: [
        ListTile(leading: const Icon(Icons.person_outline), title: Text(l10n.signedInAs(backend.userEmail ?? ''))),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.workspaces_outline),
          title: Text(l10n.workspace),
          subtitle: Text(org?.name ?? ''),
          trailing: orgs.length > 1
              ? PopupMenuButton<String>(
                  tooltip: l10n.switchWorkspace,
                  onSelected: (id) => ref.read(selectedOrgIdProvider.notifier).select(id),
                  itemBuilder: (_) => [for (final o in orgs) PopupMenuItem(value: o.id, child: Text(o.name))],
                )
              : null,
        ),
        if (isAdmin)
          ListTile(leading: const Icon(Icons.person_add_alt), title: Text(l10n.inviteMember), onTap: () => _invite(context, ref)),
        ListTile(leading: const Icon(Icons.key_outlined), title: Text(l10n.modelKeys), onTap: () => context.push('/settings/keys')),
        ListTile(leading: const Icon(Icons.menu_book_outlined), title: Text(l10n.skills), onTap: () => context.push('/settings/skills')),
        ListTile(
          key: const Key('settingsIntegrations'),
          leading: const Icon(Icons.extension_outlined),
          title: Text(l10n.integrations),
          onTap: () => context.push('/settings/integrations'),
        ),
        ListTile(
          key: const Key('settingsComputers'),
          leading: const Icon(Icons.computer_outlined),
          title: Text(l10n.computers),
          onTap: () => context.push('/settings/computers'),
        ),
        if (ref.watch(adminOverviewProvider).value != null)
          ListTile(
            key: const Key('settingsAdmin'),
            leading: const Icon(Icons.admin_panel_settings_outlined),
            title: Text(l10n.adminConsole),
            onTap: () => context.push('/settings/admin'),
          ),
        if (ref.watch(companionProvider).supported)
          ListTile(
            key: const Key('settingsCompanion'),
            leading: const Icon(Icons.laptop_mac),
            title: Text(l10n.useThisComputer),
            onTap: () => context.push('/settings/companion'),
          ),
        ListTile(
          key: const Key('settingsSecrets'),
          leading: const Icon(Icons.lock_outline),
          title: Text(l10n.secrets),
          onTap: () => context.push('/settings/secrets'),
        ),
        if (ref.watch(billingProvider).value?.enabled ?? false)
          ListTile(
            key: const Key('settingsBilling'),
            leading: const Icon(Icons.workspace_premium_outlined),
            title: Text(l10n.billing),
            subtitle: Text(ref.watch(billingProvider).value!.planName),
            onTap: () => context.push('/settings/billing'),
          ),
        ListTile(
          leading: const Icon(Icons.payments_outlined),
          title: Text(l10n.usage),
          subtitle: Text(l10n.usageMonth(formatUsd(month?.totalCostUsd ?? 0))),
        ),
        ListTile(leading: const Icon(Icons.translate), title: Text(l10n.language), subtitle: Text(Localizations.localeOf(context).toLanguageTag())),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.logout),
          title: Text(l10n.signOut),
          onTap: () => runGuarded(context, backend.signOut),
        ),
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
