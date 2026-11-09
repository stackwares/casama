import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kasama_sdk/kasama_sdk.dart';

import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../settings/model_keys_screen.dart';
import 'model_picker.dart';
import 'template_picker.dart';

String botStatusLabel(BuildContext context, BotStatusEnum s) => switch (s) {
  BotStatusEnum.working => context.l10n.botStatusWorking,
  BotStatusEnum.waiting => context.l10n.botStatusWaiting,
  BotStatusEnum.disabled => context.l10n.botStatusDisabled,
  _ => context.l10n.botStatusIdle,
};

/// The list of bots with status, today's cost and a new-bot button.
class BotsList extends ConsumerWidget {
  const BotsList({super.key, this.selectedBotId});
  final String? selectedBotId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final bots = ref.watch(botsProvider);
    final usage = ref.watch(usageTodayProvider).value;
    double costFor(String botId) => (usage?.byBot.where((b) => b.botId == botId).fold<num>(0, (n, b) => n + b.costUsd) ?? 0).toDouble();

    return AsyncView(
      value: bots,
      onRetry: () => ref.invalidate(botsProvider),
      data: (items) => items.isEmpty
          ? EmptyState(
              icon: Icons.smart_toy_outlined,
              message: l10n.noBots,
              action: FilledButton.icon(
                onPressed: () => showCreateBot(context, ref),
                icon: const Icon(Icons.add),
                label: Text(l10n.newBot),
              ),
            )
          : RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(botsProvider);
                ref.invalidate(usageTodayProvider);
              },
              child: ListView(
                children: [
                  for (final b in items)
                    ListTile(
                      key: Key('bot-${b.id}'),
                      selected: b.id == selectedBotId,
                      leading: CircleAvatar(child: Text(b.name.isEmpty ? '?' : b.name.characters.first.toUpperCase())),
                      title: Text(b.name),
                      subtitle: Text('${botStatusLabel(context, b.status)} · ${l10n.costToday(formatUsd(costFor(b.id)))}'),
                      trailing: b.status == BotStatusEnum.working
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : null,
                      onTap: () => context.go('/bots/${b.id}/chat'),
                    ),
                ],
              ),
            ),
    );
  }
}

class BotsScreen extends ConsumerWidget {
  const BotsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.bots)),
      body: const BotsList(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showCreateBot(context, ref),
        icon: const Icon(Icons.add),
        label: Text(context.l10n.newBot),
      ),
    );
  }
}

Future<void> showCreateBot(BuildContext context, WidgetRef ref) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const CreateBotSheet(),
  );
}

class CreateBotSheet extends ConsumerStatefulWidget {
  const CreateBotSheet({super.key});

  @override
  ConsumerState<CreateBotSheet> createState() => _CreateBotSheetState();
}

class _CreateBotSheetState extends ConsumerState<CreateBotSheet> {
  final _name = TextEditingController();
  final _persona = TextEditingController();
  String _model = '';
  var _modelPicked = false;
  String? _autoName;
  String? _credentialId;
  String? _templateId;
  var _busy = false;

  /// Keys that run chat models; search, image and voice keys can't drive a bot.
  static const _chatProviders = {
    ProviderId.openrouter,
    ProviderId.openai,
    ProviderId.anthropic,
    ProviderId.google,
    ProviderId.xai,
    ProviderId.openaiCompatible,
  };

  @override
  void dispose() {
    _name.dispose();
    _persona.dispose();
    super.dispose();
  }

  /// The name follows the starting point (Chief for a blank bot, else the template's name) until
  /// the user types their own.
  void _setAutoName(String name) {
    if (_name.text.trim().isEmpty || _name.text == _autoName) _name.text = name;
    _autoName = name;
  }

  /// Suggests the server's default model for the chosen key until the user picks one.
  void _fillDefaultModel(List<Credential> keys) {
    if (_modelPicked) return;
    for (final k in keys) {
      if (k.id == _credentialId) _model = ref.read(backendProvider).defaultModelFor(k.provider.value) ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final keysAsync = ref.watch(credentialsProvider);
    final keys = (keysAsync.value ?? const <Credential>[]).where((k) => _chatProviders.contains(k.provider)).toList();
    if (_credentialId == null || !keys.any((k) => k.id == _credentialId)) {
      _credentialId = keys.isEmpty ? null : keys.first.id;
      _fillDefaultModel(keys);
    }
    if (_autoName == null) _setAutoName(l10n.defaultBotName);
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, MediaQuery.viewInsetsOf(context).bottom + 16),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.newBot, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            TemplatePicker(
              selected: _templateId,
              onChanged: (t) => setState(() {
                _templateId = t?.id;
                _setAutoName(t?.name ?? l10n.defaultBotName);
              }),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _name,
              decoration: InputDecoration(labelText: l10n.botName),
              autofocus: true,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            if (keysAsync.hasValue && keys.isEmpty) ...[
              Text(l10n.addModelKeyFirst, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 8),
              AddKeyForm(onAdded: () => ref.invalidate(credentialsProvider)),
            ] else ...[
              DropdownButtonFormField<String>(
                key: ValueKey('key-$_credentialId-${keys.length}'),
                initialValue: _credentialId,
                decoration: InputDecoration(labelText: l10n.modelKey),
                items: [for (final k in keys) DropdownMenuItem(value: k.id, child: Text('${k.label} (${k.provider.value})'))],
                onChanged: (v) => setState(() {
                  _credentialId = v;
                  _modelPicked = false;
                  _fillDefaultModel(keys);
                }),
              ),
              const SizedBox(height: 8),
              ModelPickerField(
                credentialId: _credentialId,
                value: _model,
                onChanged: (m) => setState(() {
                  _model = m;
                  _modelPicked = true;
                }),
              ),
            ],
            const SizedBox(height: 8),
            TextField(
              controller: _persona,
              decoration: InputDecoration(labelText: l10n.persona, hintText: l10n.personaHint),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _busy || _credentialId == null || _model.isEmpty || _name.text.trim().isEmpty
                  ? null
                  : () async {
                      setState(() => _busy = true);
                      final org = ref.read(currentOrgProvider)!;
                      final bot = await runGuarded(
                        context,
                        () => ref
                            .read(backendProvider)
                            .createBot(
                              org.id,
                              name: _name.text.trim(),
                              credentialId: _credentialId!,
                              model: _model,
                              persona: _persona.text.trim(),
                              templateId: _templateId,
                            ),
                      );
                      if (!context.mounted) return;
                      setState(() => _busy = false);
                      if (bot != null) {
                        ref.invalidate(botsProvider);
                        final router = GoRouter.of(context);
                        Navigator.of(context).pop();
                        router.go('/bots/${bot.id}/chat');
                      }
                    },
              child: Text(l10n.create),
            ),
          ],
        ),
      ),
    );
  }
}
