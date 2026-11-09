import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kasama_sdk/kasama_sdk.dart';

import '../../core/providers.dart';
import '../../core/widgets.dart';

/// A provider's name as people know it, with what it is for when that isn't obvious.
String providerLabel(ProviderId p) => switch (p) {
      ProviderId.openrouter => 'OpenRouter',
      ProviderId.openai => 'OpenAI',
      ProviderId.anthropic => 'Anthropic',
      ProviderId.google => 'Google Gemini',
      ProviderId.xai => 'xAI',
      ProviderId.openaiCompatible => 'OpenAI-compatible server',
      ProviderId.fal => 'fal.ai',
      ProviderId.braveSearch => 'Brave Search',
      ProviderId.tavily => 'Tavily',
      ProviderId.deepgram => 'Deepgram',
      ProviderId.elevenlabs => 'ElevenLabs',
      ProviderId.cartesia => 'Cartesia',
      ProviderId.fishAudio => 'Fish Audio',
    };

String? _providerHint(BuildContext context, ProviderId p) => switch (p) {
      ProviderId.openrouter => context.l10n.providerHintOpenRouter,
      ProviderId.openaiCompatible => context.l10n.providerHintCompatible,
      ProviderId.fal => context.l10n.providerHintImages,
      ProviderId.braveSearch || ProviderId.tavily => context.l10n.providerHintSearch,
      ProviderId.deepgram || ProviderId.elevenlabs || ProviderId.cartesia || ProviderId.fishAudio => context.l10n.providerHintVoice,
      _ => null,
    };

/// Form to add a model key; the key goes to Vault and is never shown again.
class AddKeyForm extends ConsumerStatefulWidget {
  const AddKeyForm({super.key, required this.onAdded});
  final VoidCallback onAdded;

  @override
  ConsumerState<AddKeyForm> createState() => _AddKeyFormState();
}

class _AddKeyFormState extends ConsumerState<AddKeyForm> {
  var _provider = ProviderId.openrouter;
  final _label = TextEditingController(text: 'Main');
  final _key = TextEditingController();
  final _baseUrl = TextEditingController();
  var _busy = false;

  @override
  void dispose() {
    _label.dispose();
    _key.dispose();
    _baseUrl.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final org = ref.read(currentOrgProvider);
    if (org == null) return;
    setState(() => _busy = true);
    final added = await runGuarded(
      context,
      () => ref.read(backendProvider).addCredential(
            org.id,
            _provider,
            _label.text.trim().isEmpty ? 'Main' : _label.text.trim(),
            apiKey: _key.text.trim().isEmpty ? null : _key.text.trim(),
            baseUrl: _baseUrl.text.trim().isEmpty ? null : _baseUrl.text.trim(),
          ),
    );
    if (mounted) setState(() => _busy = false);
    if (added != null) {
      _key.clear();
      widget.onAdded();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final compatible = _provider == ProviderId.openaiCompatible;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      DropdownButtonFormField<ProviderId>(
        initialValue: _provider,
        decoration: InputDecoration(labelText: l10n.provider),
        items: [
          for (final p in ProviderId.values)
            DropdownMenuItem(
              value: p,
              child: Text.rich(TextSpan(text: providerLabel(p), children: [
                if (_providerHint(context, p) case final hint?)
                  TextSpan(text: '  $hint', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13)),
              ])),
            ),
        ],
        selectedItemBuilder: (context) => [for (final p in ProviderId.values) Text(providerLabel(p))],
        onChanged: (v) => setState(() => _provider = v ?? _provider),
      ),
      const SizedBox(height: 8),
      TextField(controller: _label, decoration: InputDecoration(labelText: l10n.label)),
      const SizedBox(height: 8),
      TextField(
        key: const Key('apiKey'),
        controller: _key,
        decoration: InputDecoration(labelText: l10n.apiKey, prefixIcon: const Icon(Icons.key_rounded, size: 20)),
        obscureText: true,
        autocorrect: false,
        enableSuggestions: false,
      ),
      if (compatible) ...[
        const SizedBox(height: 8),
        TextField(controller: _baseUrl, decoration: InputDecoration(labelText: l10n.baseUrl, hintText: 'http://localhost:11434/v1')),
      ],
      const SizedBox(height: 8),
      FilledButton(key: const Key('addKey'), onPressed: _busy ? null : _add, child: Text(l10n.addKey)),
    ]);
  }
}

class ModelKeysScreen extends ConsumerWidget {
  const ModelKeysScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final keys = ref.watch(credentialsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.modelKeys)),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        AsyncView(
          value: keys,
          onRetry: () => ref.invalidate(credentialsProvider),
          data: (items) => items.isEmpty
              ? Padding(padding: const EdgeInsets.all(16), child: Text(l10n.noKeys))
              : Column(children: [
                  for (final k in items)
                    Card(
                      child: ListTile(
                        leading: Icon(
                          k.lastTestOk == null ? Icons.key : (k.lastTestOk! ? Icons.check_circle : Icons.error),
                          color: k.lastTestOk == false ? Theme.of(context).colorScheme.error : null,
                        ),
                        title: Text(k.label),
                        subtitle: Text('${k.provider.value}${k.keyHint == null ? '' : ' · …${k.keyHint}'}'),
                        trailing: TextButton(
                          onPressed: () async {
                            final r = await runGuarded(context, () => ref.read(backendProvider).testCredential(k.id));
                            if (r == null || !context.mounted) return;
                            showMessage(context, r.ok ? l10n.keyOk(r.model, r.latencyMs) : l10n.keyFailed(r.error ?? ''));
                            ref.invalidate(credentialsProvider);
                          },
                          child: Text(l10n.testKey),
                        ),
                      ),
                    ),
                ]),
        ),
        const SizedBox(height: 24),
        Text(l10n.addKey, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        AddKeyForm(onAdded: () => ref.invalidate(credentialsProvider)),
      ]),
    );
  }
}
