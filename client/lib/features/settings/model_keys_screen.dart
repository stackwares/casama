import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:casama_sdk/casama_sdk.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/display_text.dart';
import '../../core/billing.dart';
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
import '../../core/remote_content.dart';
import '../bots/model_picker.dart';
import 'provider_picker.dart';
import 'who_runs_choice.dart';

/// Casama Cloud's shared OpenRouter key (D-186). The same id the server uses.
const casamaCloudCredentialId = '00000000-0000-4000-8000-0000000000c1';

/// What each chat or multi-feature key covers on the Models page.
String? keyCoversLabel(BuildContext context, ProviderId p) {
  final l10n = context.l10n;
  return switch (p) {
    ProviderId.openrouter => l10n.keyCoversOpenRouter,
    ProviderId.google => l10n.keyCoversGoogle,
    ProviderId.openai => l10n.keyCoversOpenAi,
    ProviderId.anthropic ||
    ProviderId.xai ||
    ProviderId.chatgpt ||
    ProviderId.openaiCompatible => l10n.keyCoversChat,
    _ => null,
  };
}

/// A provider's name as people know it, with what it is for when that isn't obvious.
String providerLabel(ProviderId p) => switch (p) {
  ProviderId.openrouter => 'OpenRouter',
  ProviderId.openai => 'OpenAI',
  ProviderId.anthropic => 'Anthropic',
  ProviderId.google => 'Google Gemini',
  ProviderId.xai => 'xAI',
  ProviderId.openaiCompatible => 'OpenAI-compatible server',
  ProviderId.braveSearch => 'Brave Search',
  ProviderId.tavily => 'Tavily',
  ProviderId.parallel => 'Parallel',
  ProviderId.serper => 'Serper',
  ProviderId.treg => 'Treg',
  ProviderId.googleMaps => 'Google Maps',
  ProviderId.mapbox => 'Mapbox',
  ProviderId.chatgpt => 'ChatGPT',
};

// The add-key form's groups, order and hints, and the Casama Cloud keys, come from the server
// (`backend.keyProviders`, D-374); core/key_providers.dart holds the one fallback.

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
        : l10n.chatGptConnected(cred.account.orPlaceholder(l10n.chatGptPlan)),
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

/// Form to add a model key; the key goes to Vault and is never shown again.
class AddKeyForm extends ConsumerStatefulWidget {
  const AddKeyForm({super.key, required this.onAdded, this.initialProvider, this.providers});
  final VoidCallback onAdded;

  /// Limits the form to these providers, with no ChatGPT sign-in (Casama Cloud). Null offers all.
  final List<ProviderId>? providers;

  /// The provider picked when the form opens (from a link such as "Use a local model").
  final ProviderId? initialProvider;

  @override
  ConsumerState<AddKeyForm> createState() => _AddKeyFormState();
}

class _AddKeyFormState extends ConsumerState<AddKeyForm> {
  late var _provider = (widget.providers ?? ref.read(backendProvider).keyProviders.all).contains(widget.initialProvider)
      ? widget.initialProvider!
      : widget.providers?.first ?? ProviderId.openrouter;
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

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final compatible = _provider == ProviderId.openaiCompatible;
    final only = widget.providers;
    final chatGpt = only == null && ref.watch(backendProvider).chatGptSignIn;
    final groups = ref.watch(backendProvider).keyProviders;
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
        // Chat models first as logo tiles; search, maps and the rest under "More providers" (D-182).
        ProviderPicker(
          primary: only == null ? groups.chat : [for (final p in only) if (groups.chat.contains(p)) p],
          more: only == null ? groups.more : [for (final p in only) if (!groups.chat.contains(p)) p],
          value: _provider,
          hint: (p) => groups.hint(context, p),
          onChanged: (v) => setState(() => _provider = v),
        ),
        TextField(
          controller: _label,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: l10n.label,
            prefixIcon: const Icon(LucideIcons.tag, size: 20),
          ),
        ),
        Revealable(
          builder: (context, hidden, toggle) => TextField(
            key: const Key('apiKey'),
            controller: _key,
            textInputAction: compatible ? TextInputAction.next : TextInputAction.done,
            onSubmitted: compatible || _busy ? null : (_) => _add(),
            decoration: InputDecoration(
              labelText: l10n.apiKey,
              prefixIcon: const Icon(LucideIcons.keyRound, size: 20),
              helperText: l10n.storedEncrypted,
              // A hidden field on a phone often has no paste menu, so the clipboard has its own button.
              suffixIcon: FieldSuffix(
                child: Row(
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
            ),
            obscureText: hidden,
            autocorrect: false,
            enableSuggestions: false,
          ),
        ),
        if (compatible)
          TextField(
            controller: _baseUrl,
            textInputAction: TextInputAction.done,
            onSubmitted: _busy ? null : (_) => _add(),
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
    final billing = ref.watch(billingProvider).value;
    final cloud = billing?.enabled == true;
    final ownProviders = ref.watch(backendProvider).ownProviders;
    final serviceOnly = cloud && !ownProviders;
    final cloudKeys = ref.watch(backendProvider).keyProviders.cloud;
    return SubPage(
      title: serviceOnly ? l10n.serviceKeys : (cloud ? l10n.modelsTitle : l10n.modelKeys),
      children: [
        FormNote(serviceOnly ? l10n.serviceKeysIntro : (cloud ? l10n.modelsIntro : l10n.modelKeysIntro)),
        // Keys are per workspace; say which, so a new workspace's empty list isn't a surprise.
        if (org != null) ...[
          const SizedBox(height: AppSpace.xs),
          FormNote(l10n.modelKeysFor(org.name), icon: LucideIcons.building2),
        ],
        if (cloud && ownProviders && org != null)
          _WhoRunsYourBotsSection(org: org, billing: billing),
        SectionHeader(title: l10n.yourKeys),
        AsyncView(
          value: keys,
          onRetry: () => ref.invalidate(credentialsProvider),
          loading: const _KeysSkeleton(),
          data: (items) {
            final ordered = serviceOnly
                ? items.where((k) => cloudKeys.contains(k.provider)).toList()
                : [
                    ...items.where((k) => k.id == casamaCloudCredentialId),
                    ...items.where((k) => k.id != casamaCloudCredentialId),
                  ];
            return ordered.isEmpty
                ? AppCard(
                    child: FormNote(serviceOnly ? l10n.noServiceKeys : l10n.noKeys, icon: LucideIcons.keyRound),
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
            providers: serviceOnly ? cloudKeys : null,
            initialProvider: ProviderId.values
                .where((p) => p.value == provider)
                .firstOrNull,
            onAdded: () => ref.invalidate(credentialsProvider),
          ),
        ),
        if (ownProviders) ...[
          const SizedBox(height: AppSpace.sm),
          FormNote(l10n.ownProviderPrivacyNote, icon: LucideIcons.shield),
        ],
      ],
    );
  }
}

/// Workspace default for who runs bots on Casama Cloud when own providers are enabled.
class _WhoRunsYourBotsSection extends ConsumerStatefulWidget {
  const _WhoRunsYourBotsSection({required this.org, required this.billing});
  final OrganizationWithRole org;
  final BillingSummary? billing;

  @override
  ConsumerState<_WhoRunsYourBotsSection> createState() => _WhoRunsYourBotsSectionState();
}

class _WhoRunsYourBotsSectionState extends ConsumerState<_WhoRunsYourBotsSection> {
  // Set while an admin is switching to their own provider (or to another key) but that key has no
  // default model: the key and model pickers show, and picking a model saves the switch.
  bool _pickingOwn = false;
  String? _pendingKeyId;

  @override
  Widget build(BuildContext context) {
    final org = widget.org;
    final billing = widget.billing;
    final l10n = context.l10n;
    final keys = (ref.watch(credentialsProvider).value ?? const <Credential>[])
        .where((k) => k.id != casamaCloudCredentialId && chatKeyProviders(ref).contains(k.provider))
        .toList();
    final casamaAvailable = billing?.casamaModels != BillingSummaryCasamaModelsEnum.off;
    final admin = org.role != OrgRole.member;
    final current = org.modelDefault;
    final source = !casamaAvailable
        ? WorkspaceModelDefaultSource_Enum.own
        : (current?.source_ ?? WorkspaceModelDefaultSource_Enum.casama);
    final pendingKey = keys.where((k) => k.id == _pendingKeyId).firstOrNull;
    final savedKey = keys.where((k) => k.id == current?.credentialId).firstOrNull;
    final chosenKey = pendingKey ?? savedKey ?? keys.firstOrNull;
    // The saved model only belongs to the saved key; another key starts from its provider's default.
    final chosenModel = (chosenKey != null && chosenKey.id == current?.credentialId ? current?.model : null) ??
        (chosenKey == null ? '' : (ref.watch(backendProvider).defaultModelFor(chosenKey.provider.value) ?? ''));
    final showPickers = (source == WorkspaceModelDefaultSource_Enum.own || _pickingOwn) && keys.isNotEmpty;

    Future<void> save(WorkspaceModelDefault next) async {
      if (!admin) return;
      await runGuarded(
        context,
        () => ref.read(backendProvider).updateOrg(org.id, modelDefault: next),
      );
      ref.invalidate(organizationsProvider);
      ref.invalidate(botsProvider);
      if (mounted) {
        setState(() {
          _pickingOwn = false;
          _pendingKeyId = null;
        });
      }
    }

    // Switching to your own provider needs a chat-capable key and a model. Say what's missing
    // instead of ignoring the tap.
    void chooseOwn() {
      if (!admin) {
        showMessage(context, l10n.whoRunsAdminOnly);
        return;
      }
      if (chosenKey == null) {
        showMessage(context, l10n.whoRunsOwnNeedsKey);
        return;
      }
      final m = chosenModel.isNotEmpty
          ? chosenModel
          : (ref.read(backendProvider).defaultModelFor(chosenKey.provider.value) ?? '');
      if (m.isEmpty) {
        // No default model for this provider: show the pickers so a model can be chosen.
        setState(() => _pickingOwn = true);
        showMessage(context, l10n.whoRunsOwnNeedsModel);
        return;
      }
      save(
        WorkspaceModelDefault(
          source_: WorkspaceModelDefaultSource_Enum.own,
          credentialId: chosenKey.id,
          model: m,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(title: l10n.whoRunsYourBots),
        // The two choices are cards themselves, so they sit on the page, not inside another card.
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpace.md,
          children: [
            WhoRunsChoice(
              ownSelected: source == WorkspaceModelDefaultSource_Enum.own || _pickingOwn,
              casamaAvailable: casamaAvailable,
              ownProviders: [for (final k in keys) k.provider],
              onCasama: () {
                if (!admin) {
                  showMessage(context, l10n.whoRunsAdminOnly);
                  return;
                }
                if (source == WorkspaceModelDefaultSource_Enum.casama) {
                  // Backing out of a half-made switch to an own provider.
                  setState(() {
                    _pickingOwn = false;
                    _pendingKeyId = null;
                  });
                  return;
                }
                save(WorkspaceModelDefault(source_: WorkspaceModelDefaultSource_Enum.casama));
              },
              onOwn: () {
                if (source == WorkspaceModelDefaultSource_Enum.own) return;
                chooseOwn();
              },
            ),
            if (!admin)
              FormNote(l10n.whoRunsAdminOnly, icon: LucideIcons.lock)
            else if (keys.isEmpty)
              FormNote(l10n.whoRunsOwnNeedsKey, icon: LucideIcons.keyRound),
            if (showPickers) ...[
              OwnKeyChips(
                keys: keys,
                selectedId: chosenKey?.id,
                enabled: admin,
                onSelected: (k) {
                  // Never carry the old key's model over to a different provider.
                  final m = ref.read(backendProvider).defaultModelFor(k.provider.value) ?? '';
                  if (m.isNotEmpty) {
                    save(
                      WorkspaceModelDefault(
                        source_: WorkspaceModelDefaultSource_Enum.own,
                        credentialId: k.id,
                        model: m,
                      ),
                    );
                  } else {
                    setState(() {
                      _pickingOwn = true;
                      _pendingKeyId = k.id;
                    });
                    showMessage(context, l10n.whoRunsOwnNeedsModel);
                  }
                },
              ),
              // Non-admins see the model but can't open the list (a pick would be thrown away).
              IgnorePointer(
                ignoring: !admin,
                child: ModelPickerField(
                  key: ValueKey('workspaceDefaultModel-${chosenKey?.id}'),
                  credentialId: chosenKey?.id,
                  value: chosenModel,
                  onChanged: (m) {
                    if (!admin || chosenKey == null || m.isEmpty) return;
                    save(
                      WorkspaceModelDefault(
                        source_: WorkspaceModelDefaultSource_Enum.own,
                        credentialId: chosenKey.id,
                        model: m,
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

/// The keys card before it loads: [_KeyRow]-shaped rows with a status pill and a menu button.
class _KeysSkeleton extends StatelessWidget {
  const _KeysSkeleton();

  @override
  Widget build(BuildContext context) {
    return SkeletonScope(
      child: SkeletonGroupedCard(
        rows: [
          for (final (t, st) in const [(0.5, 0.7), (0.36, 0.56)])
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: SkeletonRow(padding: EdgeInsets.zero, trailing: SkeletonTrailing.none, titleWidth: t, subtitleWidth: st),
                  ),
                  const SizedBox(width: AppSpace.xs),
                  const SkeletonBone(width: 64, height: 22, radius: AppRadius.pill),
                  const SizedBox(width: AppSpace.xs),
                  const SizedBox(width: 48, height: 48, child: Center(child: SkeletonBone(width: 18, height: 6, radius: 3))),
                ],
              ),
            ),
        ],
      ),
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
    if (r.ok) {
      showSuccess(context, l10n.keyOk(r.model, r.latencyMs));
    } else {
      showFailure(context, l10n.keyFailed(r.error.orPlaceholder()));
    }
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
    final covers = cloud ? null : keyCoversLabel(context, k.provider);
    final baseSubtitle = cloud
        ? l10n.casamaCloudKeyHint
        : plan
        ? [
            l10n.chatGptPlan,
            if (k.account.isUsable) k.account!,
            mine ? l10n.planOnlyYou : l10n.planOtherMember,
          ].join(' · ')
        : '${providerLabel(k.provider)}${k.keyHint.isUsable ? ' · …${k.keyHint}' : ''}';
    final subtitle = covers != null && backend.ownProviders
        ? '$baseSubtitle · $covers'
        : baseSubtitle;
    final canTest = cloud ? false : (plan ? mine : admin);
    final canRemove = cloud ? false : (mine || admin);
    final onCloud = ref.watch(billingProvider).value?.enabled == true;
    final canFallback = mine || (!plan && admin && !cloud && onCloud && backend.keyProviders.runsChat.contains(k.provider));
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
              onOpened: unfocusBeforeModal,
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
                      remoteUri('chatgpt_usage', chatGptUsageUrl.toString()),
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
                if (canFallback)
                  CheckedPopupMenuItem(
                    key: const Key('fallbackOnLimit'),
                    value: 'fallback',
                    checked: k.fallbackOnLimit,
                    child: Tooltip(
                      message: onCloud && !plan ? l10n.useCasamaFallbackHelp : l10n.useNextModelAtLimitHelp,
                      child: Text(onCloud && !plan ? l10n.useCasamaFallback : l10n.useNextModelAtLimit),
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
