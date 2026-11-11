import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:casama_sdk/casama_sdk.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../ui/adaptive_modal.dart';
import '../../ui/app_card.dart';
import '../../ui/form_sheet.dart';
import '../../ui/page.dart';
import '../../ui/glow_button.dart';
import '../../ui/revealable.dart';

/// Casama Cloud's shared OpenRouter key (D-186). The same id the server uses.
const casamaCloudCredentialId = '00000000-0000-4000-8000-0000000000c1';

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
  ProviderId.treg => 'Treg',
  ProviderId.googleMaps => 'Google Maps',
  ProviderId.mapbox => 'Mapbox',
  ProviderId.deepgram => 'Deepgram',
  ProviderId.elevenlabs => 'ElevenLabs',
  ProviderId.cartesia => 'Cartesia',
  ProviderId.fishAudio => 'Fish Audio',
  ProviderId.chatgpt => 'ChatGPT',
};

/// Chat-model providers: what most people add a key for, so the add-key form lists them first (D-182).
const chatKeyProviders = [
  ProviderId.openrouter,
  ProviderId.openai,
  ProviderId.anthropic,
  ProviderId.google,
  ProviderId.xai,
];

const _moreKeyOrder = [
  ProviderId.deepgram,
  ProviderId.elevenlabs,
  ProviderId.cartesia,
  ProviderId.fishAudio,
  ProviderId.braveSearch,
  ProviderId.tavily,
  ProviderId.googleMaps,
  ProviderId.mapbox,
  ProviderId.fal,
  ProviderId.treg,
  ProviderId.openaiCompatible,
];

/// Voice, search, maps, media, data and a self-hosted server, under "More providers". A provider
/// added later lands here too, so none is left out of the form.
final moreKeyProviders = [
  ..._moreKeyOrder,
  for (final p in ProviderId.values)
    if (p != ProviderId.chatgpt &&
        !chatKeyProviders.contains(p) &&
        !_moreKeyOrder.contains(p))
      p,
];

/// Keys added by pasting a key (a ChatGPT plan is connected by signing in instead).
final keyProviders = [...chatKeyProviders, ...moreKeyProviders];

/// Where people check and limit their ChatGPT plan usage (ChatGPT Settings → Usage).
final chatGptUsageUrl = Uri.parse('https://chatgpt.com/#settings');

/// "Continue with ChatGPT" (D-091). The desktop apps run the loopback sign-in; phones and the web
/// point to the desktop app or the CLI, because OpenAI redirects only to 127.0.0.1.
class ChatGptConnect extends ConsumerStatefulWidget {
  const ChatGptConnect({
    super.key,
    required this.onConnected,
    this.credentialId,
    this.compact = false,
  });
  final VoidCallback onConnected;

  /// Reconnect this plan instead of connecting a new one.
  final String? credentialId;

  /// Just the button (used inside a key row's reconnect flow).
  final bool compact;

  @override
  ConsumerState<ChatGptConnect> createState() => _ChatGptConnectState();
}

/// Runs the sign-in and reports the outcome. Returns the credential when it connected.
Future<Credential?> connectChatGptPlan(
  BuildContext context,
  WidgetRef ref, {
  String? credentialId,
}) async {
  final org = ref.read(currentOrgProvider);
  if (org == null) return null;
  final l10n = context.l10n;
  final cred = await runGuarded(
    context,
    () => ref
        .read(backendProvider)
        .connectChatGpt(org.id, credentialId: credentialId),
  );
  if (cred == null || !context.mounted) return cred;
  showMessage(
    context,
    cred.status == CredentialStatus.planUsageOff
        ? l10n.chatGptPlanUsageOff
        : l10n.chatGptConnected(cred.account ?? l10n.chatGptPlan),
  );
  return cred;
}

class _ChatGptConnectState extends ConsumerState<ChatGptConnect> {
  var _busy = false;

  Future<void> _connect() async {
    setState(() => _busy = true);
    final cred = await connectChatGptPlan(
      context,
      ref,
      credentialId: widget.credentialId,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (cred != null) widget.onConnected();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final backend = ref.watch(backendProvider);
    if (!backend.canConnectChatGpt) {
      return FormNote(l10n.chatGptDesktopOnly, icon: LucideIcons.monitor);
    }
    final button = OutlinedButton.icon(
      key: const Key('continueWithChatGpt'),
      style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
      onPressed: _busy ? null : _connect,
      icon: _busy
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(LucideIcons.messageCircle, size: 20),
      label: Text(_busy ? l10n.chatGptWaiting : l10n.continueWithChatGpt),
    );
    if (widget.compact) return button;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpace.sm,
      children: [FormNote(l10n.chatGptConnectHelp), button],
    );
  }
}

String? _providerHint(BuildContext context, ProviderId p) => switch (p) {
  ProviderId.openrouter => context.l10n.providerHintOpenRouter,
  ProviderId.openaiCompatible => context.l10n.providerHintCompatible,
  ProviderId.fal => context.l10n.providerHintImages,
  ProviderId.braveSearch ||
  ProviderId.tavily => context.l10n.providerHintSearch,
  ProviderId.treg => context.l10n.providerHintData,
  ProviderId.googleMaps || ProviderId.mapbox => context.l10n.providerHintMaps,
  ProviderId.deepgram ||
  ProviderId.elevenlabs ||
  ProviderId.cartesia ||
  ProviderId.fishAudio => context.l10n.providerHintVoice,
  _ => null,
};

/// Form to add a model key; the key goes to Vault and is never shown again.
class AddKeyForm extends ConsumerStatefulWidget {
  const AddKeyForm({super.key, required this.onAdded, this.initialProvider});
  final VoidCallback onAdded;

  /// The provider picked when the form opens (from a link such as "Use a local model").
  final ProviderId? initialProvider;

  @override
  ConsumerState<AddKeyForm> createState() => _AddKeyFormState();
}

class _AddKeyFormState extends ConsumerState<AddKeyForm> {
  late var _provider = keyProviders.contains(widget.initialProvider)
      ? widget.initialProvider!
      : ProviderId.openrouter;
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
      () => ref
          .read(backendProvider)
          .addCredential(
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

  DropdownMenuItem<ProviderId> _providerItem(
    BuildContext context,
    ProviderId p,
  ) => DropdownMenuItem(
    value: p,
    child: Text.rich(
      TextSpan(
        text: providerLabel(p),
        children: [
          if (_providerHint(context, p) case final hint?)
            TextSpan(
              text: '  $hint',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final compatible = _provider == ProviderId.openaiCompatible;
    final chatGpt = ref.watch(backendProvider).chatGptSignIn;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpace.md,
      children: [
        if (chatGpt) ...[
          ChatGptConnect(onConnected: widget.onAdded),
          Row(
            children: [
              const Expanded(child: Divider()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm),
                child: Text(
                  l10n.orAddApiKey,
                  style: TextStyle(
                    color: context.colorScheme.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
              ),
              const Expanded(child: Divider()),
            ],
          ),
        ],
        DropdownButtonFormField<ProviderId>(
          isExpanded: true,
          initialValue: _provider,
          decoration: InputDecoration(
            labelText: l10n.provider,
            prefixIcon: const Icon(LucideIcons.network, size: 20),
          ),
          // Chat models first; voice, search, maps and the rest under a "More providers" heading (D-182).
          items: [
            for (final p in chatKeyProviders) _providerItem(context, p),
            DropdownMenuItem<ProviderId>(
              key: const Key('moreProviders'),
              enabled: false,
              child: Row(
                children: [
                  Text(
                    l10n.moreProviders,
                    style: context.textTheme.labelMedium?.copyWith(
                      color: context.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: AppSpace.sm),
                  const Expanded(child: Divider()),
                ],
              ),
            ),
            for (final p in moreKeyProviders) _providerItem(context, p),
          ],
          selectedItemBuilder: (context) => [
            for (final p in chatKeyProviders) Text(providerLabel(p)),
            const SizedBox.shrink(),
            for (final p in moreKeyProviders) Text(providerLabel(p)),
          ],
          onChanged: (v) => setState(() => _provider = v ?? _provider),
        ),
        TextField(
          controller: _label,
          decoration: InputDecoration(
            labelText: l10n.label,
            prefixIcon: const Icon(LucideIcons.tag, size: 20),
          ),
        ),
        Revealable(
          builder: (context, hidden, toggle) => TextField(
            key: const Key('apiKey'),
            controller: _key,
            decoration: InputDecoration(
              labelText: l10n.apiKey,
              prefixIcon: const Icon(LucideIcons.keyRound, size: 20),
              helperText: l10n.storedEncrypted,
              // A hidden field on a phone often has no paste menu, so the clipboard has its own button.
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    key: const Key('pasteApiKey'),
                    tooltip: l10n.pasteLabel,
                    icon: const Icon(LucideIcons.clipboardPaste, size: 18),
                    onPressed: () async {
                      final data = await Clipboard.getData(
                        Clipboard.kTextPlain,
                      );
                      final text = data?.text?.trim();
                      if (text != null && text.isNotEmpty) {
                        setState(() => _key.text = text);
                      }
                    },
                  ),
                  toggle,
                ],
              ),
            ),
            obscureText: hidden,
            autocorrect: false,
            enableSuggestions: false,
          ),
        ),
        if (compatible)
          TextField(
            controller: _baseUrl,
            keyboardType: TextInputType.url,
            decoration: InputDecoration(
              labelText: l10n.baseUrl,
              hintText: 'http://localhost:11434/v1',
              prefixIcon: const Icon(LucideIcons.server, size: 20),
            ),
          ),
        GlowButton.icon(
          key: const Key('addKey'),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
          onPressed: _busy ? null : _add,
          icon: const Icon(LucideIcons.plus, size: 20),
          label: Text(l10n.addKey),
        ),
      ],
    );
  }
}

class ModelKeysScreen extends ConsumerWidget {
  const ModelKeysScreen({super.key, this.provider});

  /// A provider id to start the add form on, such as `openai_compatible`.
  final String? provider;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final keys = ref.watch(credentialsProvider);
    final org = ref.watch(currentOrgProvider);
    return SubPage(
      title: l10n.modelKeys,
      children: [
        FormNote(l10n.modelKeysIntro),
        // Keys are per workspace; say which, so a new workspace's empty list isn't a surprise.
        if (org != null) ...[
          const SizedBox(height: AppSpace.xs),
          FormNote(l10n.modelKeysFor(org.name), icon: LucideIcons.building2),
        ],
        SectionHeader(title: l10n.yourKeys),
        AsyncView(
          value: keys,
          onRetry: () => ref.invalidate(credentialsProvider),
          data: (items) {
            final ordered = [
              ...items.where((k) => k.id == casamaCloudCredentialId),
              ...items.where((k) => k.id != casamaCloudCredentialId),
            ];
            return ordered.isEmpty
                ? AppCard(
                    child: FormNote(l10n.noKeys, icon: LucideIcons.keyRound),
                  )
                : GroupedCard(
                    children: [for (final k in ordered) _KeyRow(credential: k)],
                  );
          },
        ),
        SectionHeader(title: l10n.addKey),
        AppCard(
          padding: const EdgeInsets.all(AppSpace.lg),
          child: AddKeyForm(
            initialProvider: ProviderId.values
                .where((p) => p.value == provider)
                .firstOrNull,
            onAdded: () => ref.invalidate(credentialsProvider),
          ),
        ),
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
    final r = await runGuarded(
      context,
      () => ref.read(backendProvider).testCredential(widget.credential.id),
    );
    if (!mounted) return;
    setState(() => _testing = false);
    if (r == null) return;
    showMessage(
      context,
      r.ok ? l10n.keyOk(r.model, r.latencyMs) : l10n.keyFailed(r.error ?? ''),
    );
    ref.invalidate(credentialsProvider);
  }

  Future<void> _remove() async {
    final l10n = context.l10n;
    final k = widget.credential;
    final ok = await showConfirm(
      context: context,
      title: l10n.removeKey,
      message: [
        l10n.removeKeyConfirm(k.label),
        if (k.provider == ProviderId.chatgpt) l10n.removeKeyChatGptNote,
      ].join(' '),
      confirmLabel: l10n.removeKey,
      destructive: true,
    );
    if (!ok || !mounted) return;
    await runGuarded(
      context,
      () => ref.read(backendProvider).deleteCredential(k.id),
    );
    ref.invalidate(credentialsProvider);
  }

  Future<void> _toggleFallback() async {
    final k = widget.credential;
    await runGuarded(
      context,
      () => ref
          .read(backendProvider)
          .updateCredential(k.id, fallbackOnLimit: !k.fallbackOnLimit),
    );
    ref.invalidate(credentialsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final k = widget.credential;
    final backend = ref.watch(backendProvider);
    final org = ref.watch(currentOrgProvider);
    final cloud = k.id == casamaCloudCredentialId;
    final plan = k.provider == ProviderId.chatgpt;
    final mine =
        plan && k.ownerUserId != null && k.ownerUserId == backend.userId;
    final admin = org != null && org.role != OrgRole.member;
    final (statusText, statusColor) = cloud
        ? (l10n.casamaCloudIncluded, colors.positive)
        : plan
        ? switch (k.status) {
            CredentialStatus.ok => (l10n.planConnected, colors.positive),
            CredentialStatus.planUsageOff => (
              l10n.planUsageOff,
              colors.warning,
            ),
            CredentialStatus.needsReconnect => (
              l10n.planNeedsReconnect,
              colors.negative,
            ),
          }
        : switch (k.lastTestOk) {
            true => (l10n.keyWorking, colors.positive),
            false => (l10n.keyFailing, colors.negative),
            null => (l10n.keyUntested, context.colorScheme.onSurfaceVariant),
          };
    final subtitle = cloud
        ? l10n.casamaCloudKeyHint
        : plan
        ? [
            l10n.chatGptPlan,
            ?k.account,
            mine ? l10n.planOnlyYou : l10n.planOtherMember,
          ].join(' · ')
        : '${providerLabel(k.provider)}${k.keyHint == null ? '' : ' · …${k.keyHint}'}';
    final canTest = cloud ? false : (plan ? mine : admin);
    final canRemove = cloud ? false : (mine || admin);
    return GroupedTile(
      icon: plan ? LucideIcons.messageCircle : LucideIcons.keyRound,
      iconColor: statusColor == colors.negative ? colors.negative : null,
      title: k.label,
      subtitle: subtitle,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          StatusLabel(text: statusText, color: statusColor, pill: true),
          const SizedBox(width: AppSpace.xs),
          if (_testing)
            const SizedBox(
              width: 48,
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else if (canTest || canRemove)
            PopupMenuButton<String>(
              key: Key('keyMenu-${k.id}'),
              tooltip: l10n.moreActions,
              icon: const Icon(LucideIcons.ellipsis, size: 20),
              onSelected: (v) async {
                switch (v) {
                  case 'test':
                    await _test();
                  case 'reconnect':
                    await connectChatGptPlan(context, ref, credentialId: k.id);
                    ref.invalidate(credentialsProvider);
                  case 'fallback':
                    await _toggleFallback();
                  case 'usage':
                    await launchUrl(
                      chatGptUsageUrl,
                      mode: LaunchMode.externalApplication,
                    );
                  case 'remove':
                    await _remove();
                }
              },
              itemBuilder: (context) => [
                if (canTest)
                  PopupMenuItem(value: 'test', child: Text(l10n.testKey)),
                if (mine && backend.canConnectChatGpt)
                  PopupMenuItem(
                    value: 'reconnect',
                    child: Text(l10n.reconnect),
                  ),
                if (mine)
                  CheckedPopupMenuItem(
                    key: const Key('fallbackOnLimit'),
                    value: 'fallback',
                    checked: k.fallbackOnLimit,
                    child: Tooltip(
                      message: l10n.useNextModelAtLimitHelp,
                      child: Text(l10n.useNextModelAtLimit),
                    ),
                  ),
                if (plan)
                  PopupMenuItem(value: 'usage', child: Text(l10n.manageUsage)),
                if (canRemove)
                  PopupMenuItem(value: 'remove', child: Text(l10n.removeKey)),
              ],
            ),
        ],
      ),
    );
  }
}
