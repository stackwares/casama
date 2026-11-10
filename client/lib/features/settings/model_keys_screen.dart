import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kasama_sdk/kasama_sdk.dart';

import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../ui/app_card.dart';
import '../../ui/form_sheet.dart';
import '../../ui/page.dart';

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
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: AppSpace.md, children: [
      DropdownButtonFormField<ProviderId>(
        initialValue: _provider,
        decoration: InputDecoration(labelText: l10n.provider, prefixIcon: const Icon(Icons.hub_outlined, size: 20)),
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
      TextField(
        controller: _label,
        decoration: InputDecoration(labelText: l10n.label, prefixIcon: const Icon(Icons.label_outline_rounded, size: 20)),
      ),
      TextField(
        key: const Key('apiKey'),
        controller: _key,
        decoration: InputDecoration(labelText: l10n.apiKey, prefixIcon: const Icon(Icons.key_rounded, size: 20), helperText: l10n.storedEncrypted),
        obscureText: true,
        autocorrect: false,
        enableSuggestions: false,
      ),
      if (compatible)
        TextField(
          controller: _baseUrl,
          keyboardType: TextInputType.url,
          decoration: InputDecoration(labelText: l10n.baseUrl, hintText: 'http://localhost:11434/v1', prefixIcon: const Icon(Icons.dns_outlined, size: 20)),
        ),
      FilledButton.icon(
        key: const Key('addKey'),
        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
        onPressed: _busy ? null : _add,
        icon: const Icon(Icons.add_rounded, size: 20),
        label: Text(l10n.addKey),
      ),
    ]);
  }
}

class ModelKeysScreen extends ConsumerWidget {
  const ModelKeysScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final keys = ref.watch(credentialsProvider);
    return SubPage(
      title: l10n.modelKeys,
      children: [
        FormNote(l10n.modelKeysIntro),
        SectionHeader(title: l10n.yourKeys),
        AsyncView(
          value: keys,
          onRetry: () => ref.invalidate(credentialsProvider),
          data: (items) => items.isEmpty
              ? AppCard(child: FormNote(l10n.noKeys, icon: Icons.key_off_outlined))
              : GroupedCard(children: [for (final k in items) _KeyRow(credential: k)]),
        ),
        SectionHeader(title: l10n.addKey),
        AppCard(padding: const EdgeInsets.all(AppSpace.lg), child: AddKeyForm(onAdded: () => ref.invalidate(credentialsProvider))),
      ],
    );
  }
}

class _KeyRow extends ConsumerStatefulWidget {
  const _KeyRow({required this.credential});
  final Credential credential;

  @override
  ConsumerState<_KeyRow> createState() => _KeyRowState();
}

class _KeyRowState extends ConsumerState<_KeyRow> {
  var _testing = false;

  Future<void> _test() async {
    final l10n = context.l10n;
    setState(() => _testing = true);
    final r = await runGuarded(context, () => ref.read(backendProvider).testCredential(widget.credential.id));
    if (!mounted) return;
    setState(() => _testing = false);
    if (r == null) return;
    showMessage(context, r.ok ? l10n.keyOk(r.model, r.latencyMs) : l10n.keyFailed(r.error ?? ''));
    ref.invalidate(credentialsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final k = widget.credential;
    final (statusText, statusColor) = switch (k.lastTestOk) {
      true => (l10n.keyWorking, colors.positive),
      false => (l10n.keyFailing, colors.negative),
      null => (l10n.keyUntested, context.colorScheme.onSurfaceVariant),
    };
    return GroupedTile(
      icon: Icons.key_rounded,
      iconColor: k.lastTestOk == false ? colors.negative : null,
      title: k.label,
      subtitle: '${providerLabel(k.provider)}${k.keyHint == null ? '' : ' · …${k.keyHint}'}',
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        StatusLabel(text: statusText, color: statusColor, pill: true),
        const SizedBox(width: AppSpace.xs),
        _testing
            ? const SizedBox(width: 64, child: Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))))
            : TextButton(onPressed: _test, child: Text(l10n.testKey)),
      ]),
    );
  }
}
