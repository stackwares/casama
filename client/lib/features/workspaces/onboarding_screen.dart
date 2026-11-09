import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kasama_sdk/kasama_sdk.dart';

import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../bots/template_picker.dart';
import '../settings/model_keys_screen.dart';

/// First run: create or join a workspace, add a model key, create a bot.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _workspace = TextEditingController();
  final _invite = TextEditingController();
  final _botName = TextEditingController(text: 'Assistant');
  final _model = TextEditingController(text: 'openai/gpt-4o-mini');
  final _persona = TextEditingController();
  String? _templateId;
  String? _credentialId;
  var _busy = false;

  @override
  void dispose() {
    for (final c in [_workspace, _invite, _botName, _model, _persona]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _guard(Future<void> Function() action) async {
    setState(() => _busy = true);
    await runGuarded(context, action);
    if (mounted) setState(() => _busy = false);
  }

  int _step(List<OrganizationWithRole> orgs, List<Credential> keys) {
    if (orgs.isEmpty) return 0;
    if (keys.isEmpty) return 1;
    return 2;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final orgs = ref.watch(organizationsProvider).value ?? const [];
    final keys = ref.watch(credentialsProvider).value ?? const [];
    final step = _step(orgs, keys);
    _credentialId ??= keys.isEmpty ? null : keys.first.id;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.onboardingTitle), actions: [
        TextButton(onPressed: () => ref.read(backendProvider).signOut(), child: Text(l10n.signOut)),
      ]),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Stepper(
            currentStep: step,
            controlsBuilder: (context, details) => const SizedBox.shrink(),
            steps: [
              Step(
                title: Text(l10n.createWorkspace),
                isActive: step == 0,
                state: step > 0 ? StepState.complete : StepState.indexed,
                content: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  TextField(key: const Key('workspaceName'), controller: _workspace, decoration: InputDecoration(labelText: l10n.workspaceName)),
                  const SizedBox(height: 8),
                  FilledButton(
                    key: const Key('createWorkspace'),
                    onPressed: _busy
                        ? null
                        : () => _guard(() async {
                              if (_workspace.text.trim().isEmpty) return;
                              final org = await ref.read(backendProvider).createOrganization(_workspace.text.trim());
                              ref.read(selectedOrgIdProvider.notifier).select(org.id);
                              ref.invalidate(organizationsProvider);
                            }),
                    child: Text(l10n.create),
                  ),
                  const Divider(height: 32),
                  Row(children: [
                    Expanded(child: TextField(controller: _invite, decoration: InputDecoration(labelText: l10n.inviteCode))),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: _busy
                          ? null
                          : () => _guard(() async {
                                await ref.read(backendProvider).acceptInvite(_invite.text.trim());
                                ref.invalidate(organizationsProvider);
                              }),
                      child: Text(l10n.join),
                    ),
                  ]),
                ]),
              ),
              Step(
                title: Text(l10n.addModelKeyTitle),
                isActive: step == 1,
                state: step > 1 ? StepState.complete : StepState.indexed,
                content: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Text(l10n.addModelKeyBody),
                  const SizedBox(height: 12),
                  AddKeyForm(onAdded: () => ref.invalidate(credentialsProvider)),
                ]),
              ),
              Step(
                title: Text(l10n.createFirstBot),
                isActive: step == 2,
                content: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  TemplatePicker(
                    selected: _templateId,
                    onChanged: (t) => setState(() {
                      _templateId = t?.id;
                      if (t != null) _botName.text = t.name;
                    }),
                  ),
                  const SizedBox(height: 8),
                  TextField(key: const Key('botName'), controller: _botName, decoration: InputDecoration(labelText: l10n.botName)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _credentialId,
                    decoration: InputDecoration(labelText: l10n.modelKey),
                    items: [for (final k in keys) DropdownMenuItem(value: k.id, child: Text('${k.label} (${k.provider.value})'))],
                    onChanged: (v) => setState(() => _credentialId = v),
                  ),
                  const SizedBox(height: 8),
                  TextField(key: const Key('model'), controller: _model, decoration: InputDecoration(labelText: l10n.model)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _persona,
                    decoration: InputDecoration(labelText: l10n.persona, hintText: l10n.personaHint),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 8),
                  FilledButton(
                    key: const Key('createBot'),
                    onPressed: _busy || _credentialId == null
                        ? null
                        : () => _guard(() async {
                              final org = ref.read(currentOrgProvider)!;
                              final bot = await ref.read(backendProvider).createBot(
                                    org.id,
                                    name: _botName.text.trim(),
                                    credentialId: _credentialId!,
                                    model: _model.text.trim(),
                                    persona: _persona.text.trim(),
                                    templateId: _templateId,
                                  );
                              ref.invalidate(botsProvider);
                              if (context.mounted) context.go('/bots/${bot.id}/chat');
                            }),
                    child: Text(l10n.create),
                  ),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
