import 'package:casama_sdk/casama_sdk.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/billing.dart';
import '../../core/dev_server.dart';
import '../../core/haptics.dart';
import '../../core/providers.dart';
import '../../core/updater.dart';
import '../../core/widgets.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../ui/adaptive_modal.dart';
import '../../ui/app_card.dart';
import '../../ui/form_sheet.dart';
import '../../ui/mascot.dart';
import '../../ui/page.dart';
import '../../ui/shell_header.dart';
import '../chat/widgets/chat_markdown.dart';
import '../../core/remote_content.dart';

/// Help & support (D-298): Casama Help, the support assistant (Casama Cloud), a message to the
/// support team, the guides, and the ids support asks for.

const kSupportEmail = 'support@casama.ai';
const kDocsUrl = 'https://docs.casama.ai';

/// The topics people pick from; "other" is what's sent when none is picked.
const supportTopics = [
  SupportTopic.billing,
  SupportTopic.broken,
  SupportTopic.account,
  SupportTopic.question,
];

String supportTopicLabel(BuildContext context, SupportTopic t) => switch (t) {
  SupportTopic.billing => context.l10n.supportTopicBilling,
  SupportTopic.broken => context.l10n.supportTopicBroken,
  SupportTopic.account => context.l10n.supportTopicAccount,
  SupportTopic.question => context.l10n.supportTopicQuestion,
  SupportTopic.other => context.l10n.supportTopicOther,
};

IconData _topicIcon(SupportTopic t) => switch (t) {
  SupportTopic.billing => LucideIcons.creditCard,
  SupportTopic.broken => LucideIcons.bug,
  SupportTopic.account => LucideIcons.circleUser,
  SupportTopic.question => LucideIcons.messageCircleQuestion,
  SupportTopic.other => LucideIcons.messageCircle,
};

/// Opens a link outside the app and says whether something took it. Overridable in tests.
final supportLaunchProvider = Provider<Future<bool> Function(Uri uri)>(
  (ref) => (uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  },
);

/// What this server offers for help; null on servers older than D-298 (email only, by mail app).
final supportConfigProvider = FutureProvider<SupportConfig?>((ref) async {
  try {
    return await ref.watch(backendProvider).supportConfig();
  } catch (_) {
    return null;
  }
});

String supportPlatform() {
  if (kIsWeb) return 'Web';
  return switch (defaultTargetPlatform) {
    TargetPlatform.iOS => 'iOS',
    TargetPlatform.android => 'Android',
    TargetPlatform.macOS => 'macOS',
    TargetPlatform.windows => 'Windows',
    TargetPlatform.linux => 'Linux',
    TargetPlatform.fuchsia => 'Fuchsia',
  };
}

/// The lines support needs to find someone: the build, the platform, the workspace (also the
/// customer id in the App Store and Google Play, D-297), the account and the server. Ids only,
/// nothing anyone could sign in with. In English on purpose: support reads it.
String supportDetails(WidgetRef ref) {
  final backend = ref.read(backendProvider);
  final org = ref.read(currentOrgProvider);
  final version = ref.read(appVersionLabelProvider).value;
  final billing = ref.read(billingProvider).value;
  return [
    'App: Casama ${version ?? '?'} on ${supportPlatform()}',
    if (org != null) 'Workspace ID: ${org.id}',
    if (backend.userId != null) 'Account ID: ${backend.userId}',
    if (billing != null && billing.enabled) 'Plan: ${billing.planCode}',
    'Server: ${serverHost(backend.apiUrl)}',
  ].join('\n');
}

/// The email body for a mail app: the person's words, then the details under a rule.
String supportEmailBody({required String message, required String details}) => [
  message.trim(),
  if (details.isNotEmpty) ...['', '---', details],
].join('\n');

/// A mailto link to support. Encoded by hand: mail apps show a '+' from queryParameters.
Uri supportEmailUri({
  required String subject,
  required String body,
}) => Uri.parse(
  'mailto:$kSupportEmail?subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}',
);

// ---------------------------------------------------------------------------------------------
// A message to the support team
// ---------------------------------------------------------------------------------------------

/// Whether a message to support says something; the same rule as the server's
/// meaningfulSupportMessage (`apps/server/src/api/routes/support.ts`): 4+ words of 2+ letters,
/// 3 of them different, 20 letters, most words with a vowel. Text in scripts without Latin
/// letters needs 10 letters.
bool supportMessageReady(String text) {
  final letters = RegExp(r'\p{L}', unicode: true).allMatches(text).length;
  final latin = RegExp('[a-zA-Z]').allMatches(text).length;
  if (latin < letters / 2) return letters >= 10;
  final words = [
    for (final m in RegExp(r"[\p{L}']+", unicode: true).allMatches(text.toLowerCase()))
      if (m[0]!.replaceAll("'", '').length >= 2) m[0]!,
  ];
  if (words.length < 4 || words.toSet().length < 3 || letters < 20) return false;
  final voweled = words.where((w) => RegExp('[aeiouy\u00e0-\u00ff]').hasMatch(w)).length;
  return voweled / words.length >= 0.6;
}

/// The sheet that writes to the support team. [topic] and [message] start it filled in (the
/// assistant's hand-off); [transcript] is the conversation with Casama Help, offered to include.
Future<void> showContactSupport(
  BuildContext context, {
  SupportTopic? topic,
  String? message,
  List<SupportMessage>? transcript,
}) => showAdaptiveSheet<void>(
  context: context,
  dialogMaxWidth: 520,
  builder: (_) => ContactSupportSheet(
    topic: topic,
    message: message,
    transcript: transcript,
  ),
);

class ContactSupportSheet extends ConsumerStatefulWidget {
  const ContactSupportSheet({
    super.key,
    this.topic,
    this.message,
    this.transcript,
  });
  final SupportTopic? topic;
  final String? message;
  final List<SupportMessage>? transcript;

  @override
  ConsumerState<ContactSupportSheet> createState() =>
      _ContactSupportSheetState();
}

class _ContactSupportSheetState extends ConsumerState<ContactSupportSheet> {
  late SupportTopic? _topic = widget.topic;
  late final _message = TextEditingController(text: widget.message ?? '');
  var _includeChat = true;
  var _busy = false;

  @override
  void initState() {
    super.initState();
    _message.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  bool get _hasChat => widget.transcript?.isNotEmpty == true;

  Future<void> _send() async {
    final l10n = context.l10n;
    final config = ref.read(supportConfigProvider).value;
    final topic = _topic ?? SupportTopic.other;
    final transcript = _includeChat && _hasChat
        ? widget.transcript!
        : const <SupportMessage>[];
    setState(() => _busy = true);
    if (config?.tickets == true) {
      // The server emails the support team, with this person's address to reply to.
      final version = ref.read(appVersionLabelProvider).value;
      if (!mounted) return;
      final sent = await runGuarded(
        context,
        () => ref
            .read(backendProvider)
            .sendSupportTicket(
              SupportTicketRequest(
                orgId: ref.read(currentOrgProvider)?.id,
                topic: topic,
                message: _message.text.trim(),
                transcript: transcript.isEmpty ? null : transcript,
                appVersion: version,
                platform: supportPlatform(),
              ),
            ),
      );
      if (!mounted) return;
      setState(() => _busy = false);
      if (sent == null) return;
      // This sheet's context dies with it, so the next one opens from the navigator's (and reads
      // its colors from its own); using ours crashed the app after a message was sent.
      final navigator = Navigator.of(context);
      navigator.pop();
      await showAdaptiveSheet<void>(
        context: navigator.context,
        dialogMaxWidth: 460,
        builder: (c) => FormSheet(
          icon: LucideIcons.mailCheck,
          iconColor: c.appColors.positive,
          title: l10n.supportSentTitle,
          subtitle: l10n.supportSentBody(sent.replyTo, sent.reference),
          submitLabel: l10n.close,
          submitKey: const Key('supportSentClose'),
          showCancel: false,
          onSubmit: () => Navigator.pop(c),
          children: const [],
        ),
      );
      return;
    }
    // Older or self-hosted servers: the person's own mail app, with everything written out.
    final details = supportDetails(ref);
    final subject = 'Casama: ${supportTopicLabel(context, topic)}';
    final chat = transcript
        .map(
          (m) =>
              '${m.role == SupportMessageRoleEnum.user ? 'Me' : 'Casama Help'}: ${m.content}',
        )
        .join('\n\n');
    final body = supportEmailBody(
      message: [
        _message.text.trim(),
        if (chat.isNotEmpty) '\n---\n$chat',
      ].join('\n'),
      details: details,
    );
    final opened = await ref.read(supportLaunchProvider)(
      supportEmailUri(subject: subject, body: body),
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (!opened) {
      // No mail app (common on desktop and the web): hand over the whole message instead.
      await Clipboard.setData(
        ClipboardData(text: 'To: $kSupportEmail\nSubject: $subject\n\n$body'),
      );
      if (!mounted) return;
      final navigator = Navigator.of(context);
      navigator.pop();
      showToast(
        navigator.context,
        l10n.supportNoMailApp(kSupportEmail),
        kind: ToastKind.info,
      );
      return;
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    final viaServer = ref.watch(supportConfigProvider).value?.tickets == true;
    return FormSheet(
      icon: LucideIcons.lifeBuoy,
      title: l10n.contactSupport,
      subtitle: viaServer
          ? l10n.contactSupportHelp
          : l10n.contactSupportHelpMail,
      submitLabel: viaServer ? l10n.supportSend : l10n.supportWriteEmail,
      submitIcon: LucideIcons.send,
      submitKey: const Key('supportSend'),
      busy: _busy,
      onSubmit: viaServer && !supportMessageReady(_message.text) ? null : _send,
      children: [
        Text(
          l10n.supportTopicPrompt,
          style: context.textTheme.labelLarge?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        Wrap(
          spacing: AppSpace.xs,
          runSpacing: AppSpace.xs,
          children: [
            for (final t in supportTopics)
              ChoiceChip(
                key: Key('supportTopic-${t.value}'),
                avatar: Icon(_topicIcon(t), size: 16),
                label: Text(supportTopicLabel(context, t)),
                selected: _topic == t,
                showCheckmark: false,
                onSelected: (on) {
                  HapticsHelper.light();
                  setState(() => _topic = on ? t : null);
                },
              ),
          ],
        ),
        TextField(
          key: const Key('supportMessage'),
          controller: _message,
          minLines: 4,
          maxLines: 10,
          maxLength: 8000,
          buildCounter: (
            _, {
            required currentLength,
            required isFocused,
            maxLength,
          }) => null,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            labelText: l10n.supportMessageLabel,
            hintText: l10n.supportMessageHint,
            alignLabelWithHint: true,
            // Said once they've started, so an empty form isn't scolding anyone.
            helperText: viaServer && _message.text.trim().isNotEmpty && !supportMessageReady(_message.text) ? l10n.supportMessageMore : null,
            helperMaxLines: 2,
          ),
        ),
        if (_hasChat)
          SwitchListTile(
            key: const Key('supportIncludeChat'),
            contentPadding: EdgeInsets.zero,
            value: _includeChat,
            onChanged: (v) => setState(() => _includeChat = v),
            title: Text(l10n.supportIncludeChat),
            subtitle: Text(l10n.supportIncludeChatHelp),
          ),
        FormNote(l10n.supportDetailsNote, icon: LucideIcons.info),
      ],
    );
  }
}

// ---------------------------------------------------------------------------------------------
// Casama Help, the assistant
// ---------------------------------------------------------------------------------------------

/// One line in the conversation with Casama Help. [error] lines are notices from the app, never
/// sent to the assistant.
class HelpLine {
  const HelpLine({
    required this.fromMe,
    required this.text,
    this.sources = const [],
    this.handoff,
    this.error = false,
    this.limit = false,
  });
  final bool fromMe;
  final String text;
  final List<SupportSource> sources;
  final SupportChatReplyHandoff? handoff;
  final bool error;

  /// The assistant can't answer more today (or for now): only a person can help.
  final bool limit;
}

class HelpChat {
  const HelpChat({this.lines = const [], this.waiting = false});
  final List<HelpLine> lines;
  final bool waiting;

  List<SupportMessage> get transcript => [
    for (final l in lines)
      if (!l.error)
        SupportMessage(
          role: l.fromMe
              ? SupportMessageRoleEnum.user
              : SupportMessageRoleEnum.assistant,
          content: l.text,
        ),
  ];

  /// The newest hand-off the assistant suggested.
  SupportChatReplyHandoff? get handoff =>
      lines.reversed.map((l) => l.handoff).nonNulls.firstOrNull;
}

/// The conversation lasts until the app closes or "New conversation"; it's never stored.
class HelpChatNotifier extends Notifier<HelpChat> {
  @override
  HelpChat build() => const HelpChat();

  void reset() => state = const HelpChat();

  Future<void> ask(
    String text, {
    required String fallbackError,
    required String limitText,
  }) async {
    final t = text.trim();
    if (t.isEmpty || state.waiting) return;
    final asked = [...state.lines, HelpLine(fromMe: true, text: t)];
    state = HelpChat(lines: asked, waiting: true);
    try {
      final version = ref.read(appVersionLabelProvider).value;
      final r = await ref
          .read(backendProvider)
          .askSupport(
            SupportChatRequest(
              orgId: ref.read(currentOrgProvider)?.id,
              messages: HelpChat(lines: asked).transcript.reversed
                  .take(40)
                  .toList()
                  .reversed
                  .toList(),
              appVersion: version,
              platform: supportPlatform(),
            ),
          );
      state = HelpChat(
        lines: [
          ...asked,
          HelpLine(
            fromMe: false,
            text: r.reply,
            sources: r.sources,
            handoff: r.handoff,
          ),
        ],
      );
    } catch (e) {
      final problem = problemOf(e);
      final limit =
          problem != null &&
          problem.code != 'rate_limited' &&
          problem.code != 'support_busy' &&
          problem.code != 'validation_failed' &&
          (problem.status == 429 || problem.status == 403);
      final message = problem?.detail ?? (limit ? limitText : fallbackError);
      state = HelpChat(
        lines: [
          ...asked,
          HelpLine(fromMe: false, text: message, error: true, limit: limit),
        ],
      );
    }
  }
}

final helpChatProvider = NotifierProvider<HelpChatNotifier, HelpChat>(
  HelpChatNotifier.new,
);

class SupportChatScreen extends ConsumerStatefulWidget {
  const SupportChatScreen({super.key, this.initial});

  /// A first question, sent as the screen opens (from the Help page's box or a suggestion).
  final String? initial;

  @override
  ConsumerState<SupportChatScreen> createState() => _SupportChatScreenState();
}

class _SupportChatScreenState extends ConsumerState<SupportChatScreen> {
  final _input = TextEditingController();
  final _focus = FocusNode();
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _input.addListener(() => setState(() {}));
    final q = widget.initial?.trim();
    if (q != null && q.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _send(q));
    }
  }

  @override
  void dispose() {
    _input.dispose();
    _focus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _toBottom() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (_scroll.hasClients) {
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: AppMotion.fast,
        curve: Curves.easeOut,
      );
    }
  });

  Future<void> _send([String? text]) async {
    final l10n = context.l10n;
    final t = (text ?? _input.text).trim();
    if (t.isEmpty) return;
    HapticsHelper.light();
    _input.clear();
    _toBottom();
    await ref
        .read(helpChatProvider.notifier)
        .ask(
          t,
          fallbackError: l10n.supportAssistantError,
          limitText: l10n.supportAssistantLimit,
        );
    _toBottom();
  }

  void _contactPerson({SupportChatReplyHandoff? handoff}) {
    final chat = ref.read(helpChatProvider);
    final h = handoff ?? chat.handoff;
    showContactSupport(
      context,
      topic: h?.topic,
      message: h?.summary,
      transcript: chat.transcript,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    final chat = ref.watch(helpChatProvider);
    final started = chat.lines.isNotEmpty;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      appBar: ShellHeader(
        title: l10n.casamaHelp,
        actions: [
          if (started)
            HeaderIconButton(
              key: const Key('supportNewChat'),
              icon: LucideIcons.squarePen,
              tooltip: l10n.supportNewChat,
              onPressed: chat.waiting
                  ? null
                  : () => ref.read(helpChatProvider.notifier).reset(),
            ),
          HeaderIconButton(
            key: const Key('supportChatEmail'),
            icon: LucideIcons.mail,
            tooltip: l10n.contactSupport,
            onPressed: () => _contactPerson(),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, c) {
                final side =
                    AppSpace.gutter +
                    AppBreakpoints.centeringInset(
                      c.maxWidth,
                      maxWidth: kPageMaxWidth,
                    );
                return ListView(
                  controller: _scroll,
                  padding: EdgeInsets.fromLTRB(
                    side,
                    AppSpace.md,
                    side,
                    AppSpace.md,
                  ),
                  children: [
                    _HelpIntro(
                      started: started,
                      onPick: chat.waiting ? null : _send,
                    ),
                    for (final line in chat.lines)
                      _HelpBubble(
                        line: line,
                        onContact: () => _contactPerson(handoff: line.handoff),
                      ),
                    if (chat.waiting) const _HelpTyping(),
                  ],
                );
              },
            ),
          ),
          Material(
            color: scheme.surface,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpace.gutter,
                  AppSpace.xs,
                  AppSpace.xs,
                  bottomInset > 0 ? AppSpace.xxs : AppSpace.sm,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: kPageMaxWidth),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: TextField(
                                key: const Key('supportInput'),
                                controller: _input,
                                focusNode: _focus,
                                minLines: 1,
                                maxLines: 5,
                                maxLength: 2000,
                                buildCounter: (
                                  _, {
                                  required currentLength,
                                  required isFocused,
                                  maxLength,
                                }) => null,
                                textCapitalization:
                                    TextCapitalization.sentences,
                                textInputAction: TextInputAction.send,
                                onSubmitted: (_) => _send(),
                                decoration: InputDecoration(
                                  hintText: l10n.supportAskHint,
                                  isDense: true,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpace.xs),
                            IconButton.filled(
                              key: const Key('supportAsk'),
                              tooltip: l10n.send,
                              onPressed:
                                  chat.waiting || _input.text.trim().isEmpty
                                  ? null
                                  : () => _send(),
                              icon: const Icon(LucideIcons.arrowUp, size: 20),
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.only(
                            top: AppSpace.xxs,
                            right: AppSpace.sm,
                          ),
                          child: Text(
                            l10n.supportAiNote,
                            textAlign: TextAlign.center,
                            style: context.textTheme.labelSmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The greeting, and before the first question a few common ones to start from.
class _HelpIntro extends ConsumerWidget {
  const _HelpIntro({required this.started, required this.onPick});
  final bool started;
  final void Function(String)? onPick;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    // The gallery's questions when the server sends them (D-372), in English only.
    final fromGallery = galleryTextFits(context) ? ref.watch(galleryListsProvider).value?.starters?.support : null;
    final starters = fromGallery != null && fromGallery.isNotEmpty
        ? [for (final s in fromGallery) s.text]
        : [
            l10n.supportStarterPurchase,
            l10n.supportStarterCancel,
            l10n.supportStarterBot,
            l10n.supportStarterHowTo,
          ];
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const MascotImage(Mascot.thinker, size: 40, animate: false),
              const SizedBox(width: AppSpace.sm),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpace.md,
                    vertical: AppSpace.sm,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHigh,
                    borderRadius: AppRadius.cardAll,
                  ),
                  child: Text(
                    l10n.supportGreeting,
                    style: context.textTheme.bodyLarge,
                  ),
                ),
              ),
            ],
          ),
          if (!started) ...[
            const SizedBox(height: AppSpace.md),
            Wrap(
              spacing: AppSpace.xs,
              runSpacing: AppSpace.xs,
              children: [
                for (final (i, s) in starters.indexed)
                  ActionChip(
                    key: Key('supportStarter-$i'),
                    label: Text(s),
                    onPressed: onPick == null ? null : () => onPick!(s),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _HelpBubble extends ConsumerWidget {
  const _HelpBubble({required this.line, required this.onContact});
  final HelpLine line;
  final VoidCallback onContact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    final colors = context.appColors;
    if (line.fromMe) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(
            bottom: AppSpace.sm,
            left: AppSpace.xxl,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.md,
            vertical: AppSpace.sm,
          ),
          decoration: BoxDecoration(
            color: scheme.primaryContainer,
            borderRadius: AppRadius.cardAll,
          ),
          child: SelectableText(
            line.text,
            style: context.textTheme.bodyLarge?.copyWith(
              color: scheme.onPrimaryContainer,
            ),
          ),
        ),
      );
    }
    if (line.error) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpace.sm),
        child: AppCard(
          key: const Key('supportNotice'),
          color: colors.warning.withValues(alpha: 0.08),
          borderColor: colors.warning.withValues(alpha: 0.3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    LucideIcons.circleAlert,
                    size: 18,
                    color: colors.warning,
                  ),
                  const SizedBox(width: AppSpace.xs),
                  Expanded(child: Text(line.text)),
                ],
              ),
              const SizedBox(height: AppSpace.xs),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onContact,
                  icon: const Icon(LucideIcons.mail, size: 16),
                  label: Text(l10n.supportAskPerson),
                ),
              ),
            ],
          ),
        ),
      );
    }
    final launch = ref.read(supportLaunchProvider);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.md, right: AppSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ChatMarkdown(data: line.text),
          if (line.sources.isNotEmpty) ...[
            const SizedBox(height: AppSpace.xs),
            Wrap(
              spacing: AppSpace.xs,
              runSpacing: AppSpace.xs,
              children: [
                for (final s in line.sources)
                  ActionChip(
                    avatar: const Icon(LucideIcons.bookOpen, size: 14),
                    label: Text(
                      s.title.split(' › ').last,
                      overflow: TextOverflow.ellipsis,
                    ),
                    tooltip: s.title,
                    visualDensity: VisualDensity.compact,
                    onPressed: () => launch(Uri.parse(s.url)),
                  ),
              ],
            ),
          ],
          if (line.handoff != null) ...[
            const SizedBox(height: AppSpace.sm),
            AppCard(
              key: const Key('supportHandoff'),
              color: scheme.primary.withValues(alpha: 0.06),
              borderColor: scheme.primary.withValues(alpha: 0.25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(LucideIcons.users, size: 18, color: scheme.primary),
                      const SizedBox(width: AppSpace.xs),
                      Expanded(
                        child: Text(
                          l10n.supportHandoffTitle,
                          style: context.textTheme.titleSmall,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.xxs),
                  Text(
                    line.handoff!.summary,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpace.sm),
                  FilledButton.icon(
                    key: const Key('supportHandoffSend'),
                    onPressed: onContact,
                    icon: const Icon(LucideIcons.send, size: 16),
                    label: Text(l10n.supportHandoffButton),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HelpTyping extends StatelessWidget {
  const _HelpTyping();

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    return Padding(
      key: const Key('supportTyping'),
      padding: const EdgeInsets.only(bottom: AppSpace.md),
      child: Row(
        children: [
          SizedBox.square(
            dimension: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: scheme.primary,
            ),
          ),
          const SizedBox(width: AppSpace.sm),
          Text(
            context.l10n.supportThinking,
            style: context.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------------------------
// The Help & support page
// ---------------------------------------------------------------------------------------------

class SupportScreen extends ConsumerStatefulWidget {
  const SupportScreen({super.key});

  @override
  ConsumerState<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends ConsumerState<SupportScreen> {
  final _question = TextEditingController();

  @override
  void dispose() {
    _question.dispose();
    super.dispose();
  }

  Future<void> _copy(String text) async {
    HapticsHelper.light();
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) showMessage(context, context.l10n.copied);
  }

  void _openChat([String? q]) {
    final text = q?.trim() ?? '';
    _question.clear();
    context.pushOnce(
      text.isEmpty
          ? '/settings/support/chat'
          : '/settings/support/chat?q=${Uri.encodeQueryComponent(text)}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    final backend = ref.watch(backendProvider);
    final org = ref.watch(currentOrgProvider);
    final billing = ref.watch(billingProvider).value;
    final config = ref.watch(supportConfigProvider).value;
    final assistant = config?.assistant == true;
    // Billing is on only on Casama Cloud; anywhere else whoever runs the server owns the accounts.
    final selfHosted = billing != null && !billing.enabled;
    final userId = backend.userId;
    final docs = config?.docsUrl ?? remoteLink('docs', kDocsUrl);
    final launch = ref.read(supportLaunchProvider);
    Widget idTile({
      required Key key,
      required IconData icon,
      required String title,
      required String value,
      String? help,
    }) => GroupedTile(
      key: key,
      icon: icon,
      title: title,
      subtitle: help == null ? value : '$value\n$help',
      onTap: () => _copy(value),
      trailing: Icon(
        LucideIcons.copy,
        size: 18,
        color: scheme.onSurfaceVariant,
      ),
    );
    return SubPage(
      title: l10n.helpAndSupport,
      children: [
        if (assistant)
          AppCard(
            key: const Key('supportAssistantCard'),
            padding: const EdgeInsets.all(AppSpace.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const MascotImage(Mascot.thinker, size: 48),
                    const SizedBox(width: AppSpace.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.casamaHelp,
                            style: context.textTheme.titleLarge,
                          ),
                          const SizedBox(height: AppSpace.xxs),
                          Text(
                            l10n.casamaHelpPitch,
                            style: context.textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpace.md),
                TextField(
                  key: const Key('supportQuestion'),
                  controller: _question,
                  textInputAction: TextInputAction.send,
                  textCapitalization: TextCapitalization.sentences,
                  onSubmitted: _openChat,
                  decoration: InputDecoration(
                    hintText: l10n.supportAskHint,
                    prefixIcon: const Icon(LucideIcons.sparkles, size: 18),
                    suffixIcon: IconButton(
                      key: const Key('supportQuestionGo'),
                      tooltip: l10n.send,
                      icon: const Icon(LucideIcons.arrowRight, size: 18),
                      onPressed: () => _openChat(_question.text),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpace.sm),
                Wrap(
                  spacing: AppSpace.xs,
                  runSpacing: AppSpace.xs,
                  children: [
                    for (final s in [
                      l10n.supportStarterPurchase,
                      l10n.supportStarterCancel,
                      l10n.supportStarterBot,
                    ])
                      ActionChip(
                        label: Text(s),
                        visualDensity: VisualDensity.compact,
                        onPressed: () => _openChat(s),
                      ),
                  ],
                ),
              ],
            ),
          ).appCardEntrance()
        else
          FormNote(l10n.supportIntro, icon: LucideIcons.lifeBuoy),
        if (selfHosted)
          FormNote(
            l10n.supportSelfHosted(serverHost(backend.apiUrl)),
            icon: LucideIcons.server,
            color: context.appColors.warning,
          ),
        SectionHeader(title: l10n.supportTalkToPerson),
        GroupedCard(
          children: [
            GroupedTile(
              key: const Key('supportContact'),
              icon: LucideIcons.mail,
              title: l10n.contactSupport,
              subtitle: l10n.contactSupportRow(config?.email ?? kSupportEmail),
              onTap: () => showContactSupport(
                context,
                transcript: ref.read(helpChatProvider).transcript,
              ),
            ),
            GroupedTile(
              key: const Key('supportDocs'),
              icon: LucideIcons.bookOpen,
              title: l10n.supportGuides,
              subtitle: l10n.supportGuidesHelp,
              trailing: Icon(
                LucideIcons.externalLink,
                size: 18,
                color: scheme.onSurfaceVariant,
              ),
              onTap: () => launch(Uri.parse(docs)),
            ),
            // Casama Cloud's public status page (D-304), same rule as the "Can't reach" bar.
            if (Uri.tryParse(backend.apiUrl)?.host == 'api.casama.ai')
              GroupedTile(
                key: const Key('supportStatus'),
                icon: LucideIcons.activity,
                title: l10n.supportStatus,
                subtitle: l10n.supportStatusHelp,
                trailing: Icon(
                  LucideIcons.externalLink,
                  size: 18,
                  color: scheme.onSurfaceVariant,
                ),
                onTap: () => launch(remoteUri('status', 'https://status.casama.ai')),
              ),
          ],
        ),
        SectionHeader(title: l10n.supportIds),
        FormNote(l10n.supportIdsHelp, icon: LucideIcons.info),
        GroupedCard(
          children: [
            if (org != null)
              idTile(
                key: const Key('supportWorkspaceId'),
                icon: LucideIcons.hash,
                title: l10n.supportWorkspaceId(org.name),
                value: org.id,
                help: billing?.enabled == true
                    ? l10n.supportWorkspaceIdHelp
                    : null,
              ),
            if (userId != null)
              idTile(
                key: const Key('supportAccountId'),
                icon: LucideIcons.circleUser,
                title: l10n.supportAccountId,
                value: userId,
              ),
            GroupedTile(
              key: const Key('supportCopyAll'),
              icon: LucideIcons.clipboardCopy,
              title: l10n.supportCopyAll,
              subtitle: l10n.supportCopyAllHelp,
              showChevron: false,
              onTap: () => _copy(supportDetails(ref)),
            ),
          ],
        ),
        const SizedBox(height: AppSpace.md),
      ],
    );
  }
}

/// "Trouble with a purchase?" under the Billing page: Casama Help when the server has it, else
/// the message to the support team, both starting on billing.
class PurchaseHelpLink extends ConsumerWidget {
  const PurchaseHelpLink({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final assistant = ref.watch(supportConfigProvider).value?.assistant == true;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpace.md),
      child: Center(
        child: TextButton.icon(
          key: const Key('purchaseHelp'),
          icon: const Icon(LucideIcons.lifeBuoy, size: 18),
          label: Text(l10n.purchaseHelp),
          onPressed: () => assistant
              ? context.pushOnce(
                  '/settings/support/chat?q=${Uri.encodeQueryComponent(l10n.supportStarterPurchase)}',
                )
              : showContactSupport(context, topic: SupportTopic.billing),
        ),
      ),
    );
  }
}
