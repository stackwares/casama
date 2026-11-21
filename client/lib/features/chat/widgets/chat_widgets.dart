import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/number_format.dart';
import '../../../core/providers.dart';
import '../../../core/widgets.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../theme/app_colors.dart';
import '../../../core/backend.dart';
import '../../../core/date_format.dart';
import '../../../theme/app_tokens.dart';
import '../../files/file_preview.dart';
import '../../settings/totp_scan.dart';
import '../../../ui/tool_words.dart';
import '../../../ui/bot_avatar.dart';
import '../../../ui/motion.dart';
import '../chat_controller.dart';
import '../read_aloud.dart';
import '../media/attachment_view.dart';
import 'bot_ui_previews.dart';
import 'chat_look.dart';
import 'chat_markdown.dart';
import 'mentions.dart';
import 'message_actions.dart';
import 'reactions.dart';
import 'shared_files.dart';
import '../../../ui/action_buttons.dart';
import '../../../ui/glow_button.dart';
import '../../../ui/adaptive_modal.dart';
import '../../../ui/form_sheet.dart';
import '../../companion/companion_controller.dart';
import '../../devices/device_labels.dart';
import '../../inbox/for_you.dart';
import 'package:casama_sdk/casama_sdk.dart';
import '../../../ui/effects.dart';
import '../../moderation/report_sheet.dart';
import '../../app_lock/confirm_identity.dart';
// The one nudge after an answered request: the watch's (D-410) or the widgets' (D-405).
import '../../watch/watch_nudge.dart';

// ---------------------------------------------------------------------------------------------
// Messages

/// What you wrote: a bubble on the right in the accent tint, the tail corner tucked in, with any
/// attached files above it.
class UserBubble extends StatelessWidget {
  const UserBubble({
    super.key,
    required this.text,
    this.attachments = const [],
    this.apps = const [],
    this.onEdit,
    this.siblingIndex = 1,
    this.siblingCount = 1,
    this.onBranch,
    this.uploading = false,
    this.onResend,
    this.onDiscard,
    this.onDelete,
    this.onReact,
    this.myReaction,
    this.sentAt,
  });
  final String text;
  final List<AttachmentRef> attachments;
  final List<MessageAppMention> apps;

  /// When it was sent (D-387), shown in its menu.
  final DateTime? sentAt;

  /// React with an emoji, and your current one (D-331).
  final ReactCallback? onReact;
  final String? myReaction;

  /// Delete this message (Add 11).
  final VoidCallback? onDelete;

  /// Set when the message didn't reach the server: "Not sent" with Try Again and Remove.
  final VoidCallback? onResend;
  final VoidCallback? onDiscard;

  /// Sent while its files upload: a quiet note says so until they are up.
  final bool uploading;

  /// Edit and resend, and the arrows between edited versions (D-108).
  final VoidCallback? onEdit;
  final int siblingIndex;
  final int siblingCount;
  final ValueChanged<int>? onBranch;

  @override
  Widget build(BuildContext context) {
    final branches = siblingCount > 1 && onBranch != null
        ? Row(
            key: const Key('branchArrows'),
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                key: const Key('branchPrev'),
                visualDensity: VisualDensity.compact,
                iconSize: 16,
                tooltip: context.l10n.previousVersion,
                onPressed: siblingIndex > 1 ? () => onBranch!(-1) : null,
                icon: const Icon(LucideIcons.chevronLeft),
              ),
              Text(
                '$siblingIndex/$siblingCount',
                style: context.textTheme.labelSmall?.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                ),
              ),
              IconButton(
                key: const Key('branchNext'),
                visualDensity: VisualDensity.compact,
                iconSize: 16,
                tooltip: context.l10n.nextVersion,
                onPressed: siblingIndex < siblingCount
                    ? () => onBranch!(1)
                    : null,
                icon: const Icon(LucideIcons.chevronRight),
              ),
            ],
          )
        : null;
    final scheme = context.colorScheme;
    final note = onResend != null
        ? Padding(
            key: const Key('notSentNote'),
            padding: const EdgeInsets.only(top: 2),
            child: Wrap(
              alignment: WrapAlignment.end,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Icon(LucideIcons.circleAlert, size: 14, color: scheme.error),
                const SizedBox(width: 4),
                Text(context.l10n.notSent, style: context.textTheme.labelSmall?.copyWith(color: scheme.error, fontWeight: FontWeight.w600)),
                TextButton.icon(
                  key: const Key('resendMessage'),
                  style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                  onPressed: onResend,
                  icon: const Icon(LucideIcons.rotateCw, size: 14),
                  label: Text(context.l10n.retry),
                ),
                if (onDiscard != null)
                  IconButton(
                    key: const Key('discardMessage'),
                    visualDensity: VisualDensity.compact,
                    iconSize: 16,
                    tooltip: context.l10n.remove,
                    onPressed: onDiscard,
                    icon: Icon(LucideIcons.x, color: scheme.onSurfaceVariant),
                  ),
              ],
            ),
          )
        : uploading
        ? Padding(
            key: const Key('uploadingNote'),
            padding: const EdgeInsets.only(top: 4, right: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 10,
                  height: 10,
                  child: CircularProgressIndicator(strokeWidth: 1.5, color: context.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(width: 6),
                Text(
                  context.l10n.uploadingAttachments,
                  style: context.textTheme.labelSmall?.copyWith(color: context.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          )
        : null;
    if (attachments.isEmpty && branches == null && note == null) return _bubble(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (attachments.isNotEmpty)
          MediaGroup(files: attachments, alignment: WrapAlignment.end),
        if (text.isNotEmpty) ...[
          if (attachments.isNotEmpty) const SizedBox(height: 6),
          _bubble(context),
        ],
        ?note,
        ?branches,
      ],
    );
  }

  Widget _bubble(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => Align(
        alignment: AlignmentDirectional.centerEnd,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: (constraints.maxWidth * 0.85).clamp(0, 560),
          ),
          child: MessageActions(
            text: text,
            sentAt: sentAt,
            onEdit: onEdit,
            onDelete: onDelete,
            onReact: onReact,
            myReaction: myReaction,
            alignEnd: true,
            // Your messages: the accent, filled, even corners (D-256). Opaque on any wallpaper.
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: ChatLook.userFill(context),
                borderRadius: BorderRadius.circular(ChatLook.bubbleRadius),
              ),
              child: Padding(
                padding: ChatLook.bubblePadding,
                child: Builder(
                  builder: (context) {
                    final style = context.textTheme.bodyLarge?.copyWith(height: 1.4, color: ChatLook.userText(context));
                    // @mentions of bots (D-118) and apps (D-434) stand out as pills.
                    final mentions = MentionScope.maybeOf(context);
                    if (mentions == null) return Text(text, style: style);
                    return Text.rich(
                      TextSpan(children: mentionSpans(mentions, text, style, messageApps: apps)),
                      style: style,
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The bot's name and mark, once at the start of each of its turns.
class BotTurnHeader extends StatelessWidget {
  const BotTurnHeader({super.key, required this.name, this.avatar, this.working = false});
  final String name;
  final String? avatar;

  /// The bot is on this turn right now: its avatar wiggles and plays while it thinks.
  final bool working;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.xs),
      child: Row(
        children: [
          if (working)
            _ThinkingWiggle(child: BotAvatar(name: name, avatar: avatar, size: 24, animate: Effects.decorative(context)))
          else
            BotAvatar(name: name, avatar: avatar, size: 24),
          const SizedBox(width: AppSpace.xs),
          Flexible(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Rocks its child side to side with a little hop, like a bot mulling something over. Its own layer,
/// so the chat around it doesn't repaint. Still with reduced motion.
class _ThinkingWiggle extends StatefulWidget {
  const _ThinkingWiggle({required this.child});
  final Widget child;

  @override
  State<_ThinkingWiggle> createState() => _ThinkingWiggleState();
}

class _ThinkingWiggleState extends State<_ThinkingWiggle> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!Effects.decorative(context)) {
      _controller.reset();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final a = _controller.value * 2 * math.pi;
        return Transform.translate(
          offset: Offset(0, -(math.sin(a * 2).abs()) * 2),
          child: Transform.rotate(angle: math.sin(a) * 0.14, child: child),
        );
      },
      child: widget.child,
    ),
  );
}

/// The bot's reply in a bubble that reads on any wallpaper. Copy, read aloud, select and share
/// live in the message menu (long-press, or right-click with a mouse).
final _shownText = Expando<String>();

final _savedId = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$');

class AssistantMessage extends StatefulWidget {
  const AssistantMessage({
    super.key,
    required this.entry,
    this.onSpeak,
    this.status,
    this.botName,
    this.botAvatar,
    this.workingIcon = true,
    this.onRegenerate,
    this.onDelete,
    this.onReact,
    this.myReaction,
  });
  final MessageEntry entry;

  /// React with an emoji, and your current one (D-331).
  final ReactCallback? onReact;
  final String? myReaction;
  final VoidCallback? onSpeak;

  /// Ask for this reply again, and delete it (Add 11).
  final VoidCallback? onRegenerate;
  final VoidCallback? onDelete;

  /// Who is replying, for the working line before the first word (D-256).
  final String? botName;
  final String? botAvatar;

  /// What the bot is doing while the reply is still empty.
  final String? status;

  /// Whether the working line shows the bot's face (group chats have it in the turn's header).
  final bool workingIcon;

  @override
  State<AssistantMessage> createState() => _AssistantMessageState();
}

class _AssistantMessageState extends State<AssistantMessage> {
  /// The reply's text keeps its state (the reveal's progress, the parsed Markdown) when the
  /// finished reply moves under the message menu, so the last words don't pop in and a long reply
  /// isn't parsed again the moment it ends.
  final _bodyKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    // The working line gives way to the reply with a quick fade while the row grows to fit it.
    final duration = AppMotion.of(context, AppMotion.fast);
    return _Grow(
      duration: duration,
      curve: AppMotion.curve,
      // The read-aloud glow reaches past the bubble.
      clip: Clip.none,
      child: AnimatedSwitcher(
        duration: duration,
        switchInCurve: AppMotion.curve,
        switchOutCurve: AppMotion.curve,
        layoutBuilder: (current, previous) => Stack(
          alignment: AlignmentDirectional.topStart,
          children: [...previous, ?current],
        ),
        child: entry.text.trim().isEmpty && entry.streaming
            ? KeyedSubtree(
                key: const ValueKey('working'),
                child: WorkingIndicator(status: widget.status ?? context.l10n.thinking, botName: widget.botName, botAvatar: widget.botAvatar, showIcon: widget.workingIcon),
              )
            : KeyedSubtree(key: const ValueKey('reply'), child: _reply(context, entry)),
      ),
    );
  }

  Widget _reply(BuildContext context, MessageEntry entry) {
    // Media the reply made (a generated image or video, D-205) shows under its text.
    final media = entry.attachments;
    // A finished reply with no words (only a card or a tool step, or links that show as cards)
    // draws nothing rather than an empty bubble.
    final shown = entry.streaming ? entry.text : (_shownText[entry] ??= textWithoutSharedLinks(entry.text, alreadyShown: media));
    if (shown.trim().isEmpty && media.isEmpty) return const SizedBox.shrink();
    if (shown.trim().isEmpty && media.isNotEmpty) {
      return Align(
        alignment: AlignmentDirectional.centerStart,
        child: MediaGroup(files: media),
      );
    }
    final scheme = context.colorScheme;
    // While it's read aloud the bubble lights up in the accent, like the player above the composer.
    Widget bubble(bool reading) => AnimatedContainer(
      duration: AppMotion.of(context, AppMotion.duration),
      curve: AppMotion.curve,
      // Filled, even corners, no border or shadow (D-256); an accent edge while it's read aloud.
      decoration: BoxDecoration(
        color: ChatLook.botFill(context),
        borderRadius: BorderRadius.circular(ChatLook.bubbleRadius),
        border: Border.all(
          color: reading ? scheme.primary.withValues(alpha: 0.6) : Colors.transparent,
        ),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: reading ? 0.2 : 0),
            blurRadius: 18,
          ),
        ],
      ),
      child: Padding(
        padding: ChatLook.bubblePadding,
        child: _ReplyBody(key: _bodyKey, text: shown, live: entry.streaming),
      ),
    );
    final message = entry.streaming
        ? Align(alignment: AlignmentDirectional.centerStart, child: bubble(false))
        : Consumer(
            builder: (context, ref, _) {
              final reading = ref.watch(
                readAloudProvider.select((s) => s?.messageId == entry.id),
              );
              return Align(
                alignment: AlignmentDirectional.centerStart,
                child: MessageActions(
                  text: entry.text,
                  sentAt: entry.at,
                  markdown: true,
                  onRegenerate: widget.onRegenerate,
                  onDelete: widget.onDelete,
                  onReact: widget.onReact,
                  myReaction: widget.myReaction,
                  // Saved replies only (a streaming one has no server id yet; D-301).
                  onReport: _savedId.hasMatch(entry.id)
                      ? () => showReportSheet(context, kind: ReportTarget.message, targetId: entry.id)
                      : null,
                  onSpeak: widget.onSpeak,
                  speakKey: Key('speak-${entry.id}'),
                  speaking: reading,
                  child: bubble(reading),
                ),
              );
            },
          );
    if (media.isEmpty || entry.streaming) return message;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      spacing: AppSpace.xs,
      children: [message, MediaGroup(files: media)],
    );
  }
}

/// The reply's words and, while it's still coming, the typing dots.
///
/// Words come in at a steady pace instead of a sentence every 200 ms (the server's batches), with
/// half-written Markdown closed so it doesn't flash raw (see [healStreamingMarkdown]). The text
/// grows smoothly when a word wraps to a new line, and the dots fade out once the last word shows.
class _ReplyBody extends StatelessWidget {
  const _ReplyBody({super.key, required this.text, required this.live});
  final String text;
  final bool live;

  @override
  Widget build(BuildContext context) {
    final duration = AppMotion.of(context, const Duration(milliseconds: 140));
    return SmoothReveal(
      text: text,
      live: live,
      builder: (visible, revealing) {
        final going = live || revealing;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _Grow(
              duration: duration,
              child: ChatMarkdown(data: going ? healStreamingMarkdown(visible) : visible, selectable: false),
            ),
            // Its own layer: the dots animate every frame without repainting the reply's text. Once
            // the last word shows they fold away instead of the bubble jumping a row shorter.
            _Grow(
              duration: duration,
              child: going
                  ? Padding(
                      padding: const EdgeInsets.only(top: AppSpace.xs),
                      child: RepaintBoundary(child: _TypingDots(color: context.colorScheme.primary)),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        );
      },
    );
  }
}

/// Animates its child's size changes, top-start anchored; nothing at all with reduced motion
/// (a zero-length AnimatedSize trips over its own layout).
class _Grow extends StatelessWidget {
  const _Grow({required this.duration, required this.child, this.curve = Curves.easeOut, this.clip = Clip.hardEdge});
  final Duration duration;
  final Curve curve;
  final Clip clip;
  final Widget child;

  @override
  Widget build(BuildContext context) => duration == Duration.zero
      ? child
      : AnimatedSize(duration: duration, curve: curve, alignment: AlignmentDirectional.topStart, clipBehavior: clip, child: child);
}

/// Three dots that pulse in turn while a reply streams (one controller, no timers).
class _TypingDots extends StatefulWidget {
  const _TypingDots({required this.color});
  final Color color;

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < 3; i++)
            Builder(
              builder: (context) {
                // Each dot peaks a third of a cycle after the one before it.
                final phase = (_controller.value - i * 0.2) % 1.0;
                final t = phase < 0.5 ? phase * 2 : (1 - phase) * 2;
                final v = Curves.easeInOut.transform(t);
                return Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Transform.scale(
                    scale: 0.7 + 0.3 * v,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: widget.color.withValues(alpha: 0.25 + 0.75 * v),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

/// Shows [child] after [delay] (at once when it's zero); a zero delay later shows it straight away.
class ShowAfter extends StatefulWidget {
  const ShowAfter({super.key, required this.delay, required this.child});
  final Duration delay;
  final Widget child;

  @override
  State<ShowAfter> createState() => _ShowAfterState();
}

class _ShowAfterState extends State<ShowAfter> {
  Timer? _timer;
  late bool _shown = widget.delay == Duration.zero;

  @override
  void initState() {
    super.initState();
    if (!_shown) _timer = Timer(widget.delay, () => setState(() => _shown = true));
  }

  @override
  void didUpdateWidget(ShowAfter old) {
    super.didUpdateWidget(old);
    if (!_shown && widget.delay == Duration.zero) {
      _timer?.cancel();
      _shown = true;
    } else if (old.delay == Duration.zero && widget.delay > Duration.zero) {
      // It now sits under a finished reply: wait again before showing.
      _shown = false;
      _timer?.cancel();
      _timer = Timer(widget.delay, () => setState(() => _shown = true));
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _shown ? widget.child : const SizedBox.shrink();
}

/// Shows [text] growing at a steady pace, so a reply flows instead of jumping a sentence at a time.
///
/// The server sends text in batches every 200 ms. The pace follows how fast text has been arriving
/// (a moving average), staying about [lead] behind it, so words keep coming at an even speed
/// between batches instead of surging when one lands and crawling before the next. When [live]
/// turns off (the reply finished), what's left drains quickly rather than appearing at once. Text
/// that isn't a continuation (an edit, a re-run), and reduced motion, show as they are.
class SmoothReveal extends StatefulWidget {
  const SmoothReveal({super.key, required this.text, required this.builder, this.live = true});
  final String text;
  final bool live;
  final Widget Function(String visible, bool revealing) builder;

  /// How far the reveal aims to stay behind what has arrived, the slowest pace (characters a
  /// second), and the longest backlog it lets build up before hurrying.
  static const lead = Duration(milliseconds: 250);
  static const minSpeed = 40.0;
  static const maxLag = Duration(milliseconds: 1200);

  /// Before the arrival rate is known, and when draining a finished reply: the whole backlog in this long.
  static const catchUp = Duration(milliseconds: 260);

  @override
  State<SmoothReveal> createState() => _SmoothRevealState();
}

/// The reveal's pace (characters a second), kept apart from the widget so tests can drive it.
@visibleForTesting
class RevealPace {
  /// Characters a second text has been arriving at, smoothed; zero until two batches came.
  double rate = 0;
  Duration? _lastArrival;

  /// Text grew by [added] characters at [at].
  void arrived(int added, Duration at) {
    final last = _lastArrival;
    _lastArrival = at;
    if (last == null || added <= 0) return;
    final dt = ((at - last).inMicroseconds / 1e6).clamp(0.05, 1.5);
    final instant = added / dt;
    // A time constant of ~0.8 s: steady through batch jitter, quick to follow a real change.
    final alpha = 1 - math.exp(-dt / 0.8);
    rate = rate == 0 ? instant : rate + (instant - rate) * alpha;
  }

  /// How fast to reveal with [backlog] characters arrived but not shown.
  double speed(double backlog, {required bool live}) {
    double secs(Duration d) => d.inMicroseconds / 1e6;
    final catchUp = backlog / secs(SmoothReveal.catchUp);
    if (!live || rate == 0) return math.max(SmoothReveal.minSpeed * (live ? 1 : 3), catchUp);
    // Steady at the arrival rate, nudged gently toward the target lead so the pace barely
    // changes when a batch lands.
    final target = rate * secs(SmoothReveal.lead);
    var v = rate + (backlog - target) / 1.0;
    // Fallen too far behind (a burst after a pause): hurry.
    if (backlog > rate * secs(SmoothReveal.maxLag)) v = math.max(v, backlog / 0.5);
    return math.max(SmoothReveal.minSpeed, v);
  }
}

class _SmoothRevealState extends State<SmoothReveal> with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_tick);
  final _clock = Stopwatch()..start();
  final _pace = RevealPace();
  late double _shown;
  Duration _last = Duration.zero;
  String _built = '';

  @override
  void initState() {
    super.initState();
    // Opened partway through a long reply, or already finished: show what's there, then flow from it.
    _shown = !widget.live || widget.text.length > 400 ? widget.text.length.toDouble() : 0;
    _pace.arrived(widget.text.length, _clock.elapsed);
    _sync();
  }

  @override
  void didUpdateWidget(SmoothReveal old) {
    super.didUpdateWidget(old);
    if (!widget.text.startsWith(old.text)) {
      _shown = widget.text.length.toDouble();
    } else if (widget.text.length > old.text.length) {
      _pace.arrived(widget.text.length - old.text.length, _clock.elapsed);
    }
    _sync();
  }

  void _sync() {
    final behind = _shown < widget.text.length;
    if (behind && !_ticker.isActive) {
      _last = Duration.zero;
      _ticker.start();
    } else if (!behind && _ticker.isActive) {
      _ticker.stop();
    }
  }

  void _tick(Duration elapsed) {
    final dt = (elapsed - _last).inMicroseconds / 1e6;
    _last = elapsed;
    final backlog = widget.text.length - _shown;
    _shown = math.min(widget.text.length.toDouble(), _shown + _pace.speed(backlog, live: widget.live) * dt);
    final next = _visible();
    // Markdown is laid out again only when a new word shows, not every frame.
    if (next != _built) setState(() {});
    if (_shown >= widget.text.length) _ticker.stop();
  }

  /// What shows: whole words, so a word never appears letter by letter.
  String _visible() {
    final text = widget.text;
    final n = _shown.floor();
    if (n >= text.length) return text;
    final space = text.lastIndexOf(RegExp(r'\s'), n);
    return space <= 0 ? '' : text.substring(0, space);
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _built = MediaQuery.disableAnimationsOf(context) ? widget.text : _visible();
    return widget.builder(_built, _built.length < widget.text.length);
  }
}

/// What the bot is doing right now, in one line (D-256): the bot's own icon (rocking while it
/// thinks) and the status shimmering, its first word bright and the rest dimmer ("Checking
/// Vaultwarden setup"). Without a bot to show, a sparkle stands in.
class WorkingIndicator extends StatelessWidget {
  const WorkingIndicator({super.key, required this.status, this.botName, this.botAvatar, this.showIcon = true});
  final String status;

  /// Off in group chats: the turn's header right above already shows the bot, so the line only
  /// indents to sit under its name.
  final bool showIcon;
  final String? botName;
  final String? botAvatar;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final still = MediaQuery.disableAnimationsOf(context);
    final base = context.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500, height: 1.3);
    final space = status.indexOf(' ');
    final verb = space < 0 ? status : status.substring(0, space);
    final rest = space < 0 ? '' : status.substring(space);
    // Moving, the words sit dim and a bright shine sweeps across them. Dimmed by mixing toward
    // the background, not by transparency: the shine keeps the text's own opacity, so on see-through
    // text it would come out just as faint. Still, they keep full contrast.
    final verbColor = still ? scheme.onSurface : Color.lerp(scheme.onSurface, scheme.surface, 0.5)!;
    final restColor = still ? scheme.onSurfaceVariant : Color.lerp(scheme.onSurface, scheme.surface, 0.6)!;
    Widget text = Text.rich(
      TextSpan(
        children: [
          TextSpan(text: verb, style: TextStyle(color: verbColor)),
          if (rest.isNotEmpty) TextSpan(text: rest, style: TextStyle(color: restColor)),
        ],
      ),
      key: ValueKey(status),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: base,
    );
    final name = botName;
    Widget icon = name == null
        ? Icon(LucideIcons.sparkles, size: 18, color: scheme.primary)
        : BotAvatar(name: name.isEmpty ? '?' : name, avatar: botAvatar, size: 24, animate: !still && Effects.decorative(context));
    if (!still) {
      icon = name == null
          ? Pulse(from: 0.8, to: 1.1, fadeFrom: 0.55, duration: const Duration(milliseconds: 700), child: icon)
          : _ThinkingWiggle(child: icon);
      text = Shimmer(key: ValueKey(status), color: scheme.onSurface, band: 0.35, duration: const Duration(milliseconds: 1100), child: text);
    }
    return Semantics(
      liveRegion: true,
      label: status,
      // One line, no skeleton: it comes and goes between steps without pushing the chat around.
      child: ExcludeSemantics(
        child: Row(
          children: [
            if (showIcon) ...[icon, const SizedBox(width: 10)] else const SizedBox(width: 24 + AppSpace.xs),
            Flexible(
              // Fade through, left-aligned: the old line leaves before the new one shows, so two
              // statuses of different widths never sit on top of each other.
              child: AnimatedSwitcher(
                duration: AppMotion.of(context, AppMotion.duration),
                switchInCurve: const Interval(0.5, 1, curve: Curves.easeOut),
                switchOutCurve: const Interval(0.5, 1, curve: Curves.easeIn),
                layoutBuilder: (current, previous) => Stack(
                  alignment: Alignment.centerLeft,
                  children: [...previous, ?current],
                ),
                child: text,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// An attached file: a thumbnail for images, a chip for the rest. Tap to open it.
class AttachmentTile extends StatelessWidget {
  const AttachmentTile({super.key, required this.attachment});
  final AttachmentRef attachment;

  // Pictures, players, PDF cards and file cards all live in media/ (D-205).
  @override
  Widget build(BuildContext context) => AttachmentView(attachment: attachment);
}

// ---------------------------------------------------------------------------------------------
// Tool steps

/// What the bot is doing while a step runs, in everyday words ("Searching the web…"), for the
/// working line. No tool names, commands or queries (D-162).
String toolActivity(AppLocalizations l10n, String tool) {
  if (tool == 'tools.load' || tool.startsWith('skills')) {
    return l10n.activityReady;
  }
  if (tool.startsWith('web') || tool.contains('search')) {
    return l10n.activitySearching;
  }
  if (tool.startsWith('browser')) return l10n.activityBrowsing;
  if (tool.startsWith('files')) return l10n.activityFiles;
  if (tool.startsWith('media')) {
    return tool.contains('video') ? l10n.activityVideo : l10n.activityImage;
  }
  if (tool.startsWith('memory') || tool.startsWith('knowledge')) {
    return l10n.activityMemory;
  }
  if (tool.startsWith('routines') || tool.startsWith('tasks')) {
    return l10n.activityScheduling;
  }
  if (tool.startsWith('shell') ||
      tool.startsWith('desktop') ||
      tool.startsWith('computer') ||
      tool.startsWith('checkpoint')) {
    return l10n.activityComputer;
  }
  // A connected app or server by name ("Using Deepwiki…"), not just "your apps".
  if (RegExp(r'^(mcp|composio|pipedream|app|openapi|local_mcp)\.[^.]+\.').hasMatch(tool)) {
    return '${toolWords(l10n, tool).doing}…';
  }
  if (tool.startsWith('http') ||
      tool.contains('.') &&
          !tool.startsWith('ui.') &&
          !tool.startsWith('notify')) {
    return l10n.activityApps;
  }
  return l10n.activityWorking;
}

/// The server's lead-in for a failure it has no plain explanation for; the rest is technical.
const _genericFailure = 'Something went wrong while the bot was working.';

String formatDuration(int ms, String locale) => ms < 1000
    ? '${ms.humanizedCount(locale)} ms'
    : '${(ms / 1000).humanizedCount(locale, decimalDigits: ms < 10000 ? 1 : 0)} s';

/// Consecutive tool steps in one card. Long finished runs fold to their last steps.
class ToolGroupCard extends StatefulWidget {
  const ToolGroupCard({super.key, required this.steps});
  final List<ToolEntry> steps;

  @override
  State<ToolGroupCard> createState() => _ToolGroupCardState();
}

class _ToolGroupCardState extends State<ToolGroupCard> {
  var _showAll = false;
  final _open = <String>{};

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final steps = widget.steps;
    final running = steps.any((s) => s.status == ToolStatus.running);
    final folded = !_showAll && !running && steps.length > 3;
    final visible = folded ? steps.sublist(steps.length - 2) : steps;
    final totalMs = steps.fold<int>(0, (n, s) => n + (s.durationMs ?? 0));
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.colorScheme.surfaceContainerLow,
        borderRadius: AppRadius.tileAll,
        border: Border.all(color: context.appColors.hairline),
      ),
      child: ClipRRect(
        borderRadius: AppRadius.tileAll,
        child: Material(
          type: MaterialType.transparency,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (folded)
                InkWell(
                  onTap: () => setState(() => _showAll = true),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 12, 10),
                    child: Row(
                      children: [
                        Icon(
                          LucideIcons.chevronsUpDown,
                          size: 18,
                          color: context.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: AppSpace.xs),
                        Expanded(
                          child: Text(
                            l10n.showMoreSteps(steps.length - visible.length),
                            style: context.textTheme.labelLarge?.copyWith(
                              color: context.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        Text(
                          '${l10n.toolSteps(steps.length)} · ${formatDuration(totalMs, context.l10n.localeName)}',
                          style: context.textTheme.labelMedium?.copyWith(
                            color: context.colorScheme.onSurfaceVariant,
                            fontFeatures: AppText.tabular,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              for (var i = 0; i < visible.length; i++) ...[
                if (i > 0 || folded)
                  Divider(indent: 50, color: context.appColors.hairline),
                _ToolStepRow(
                  key: ValueKey(visible[i].callId),
                  entry: visible[i],
                  open: _open.contains(visible[i].callId),
                  onToggle: () => setState(
                    () => _open.contains(visible[i].callId)
                        ? _open.remove(visible[i].callId)
                        : _open.add(visible[i].callId),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ToolStepRow extends StatelessWidget {
  const _ToolStepRow({
    super.key,
    required this.entry,
    required this.open,
    required this.onToggle,
  });
  final ToolEntry entry;
  final bool open;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    final colors = context.appColors;
    // Everyday words, the same as on calls and over the computer view; the technical details are
    // behind the chevron.
    final words = toolWords(l10n, entry.tool, entry.args);
    final failed = entry.status == ToolStatus.failed;
    final running = entry.status == ToolStatus.running;
    final tint = failed ? colors.negative : toolTint(context, words.tone);
    final label = running || failed ? words.doing : words.done;
    final summary = words.detail ?? '';
    final Widget status = switch (entry.status) {
      ToolStatus.running => SizedBox(
        width: 14,
        height: 14,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          strokeCap: StrokeCap.round,
          color: scheme.primary,
        ),
      ),
      ToolStatus.done => Text(
        formatDuration(entry.durationMs ?? 0, context.l10n.localeName),
        style: context.textTheme.labelMedium?.copyWith(
          color: scheme.onSurfaceVariant,
          fontFeatures: AppText.tabular,
        ),
      ),
      ToolStatus.failed => Text(
        l10n.toolFailedLabel,
        style: context.textTheme.labelMedium?.copyWith(
          color: colors.negative,
          fontWeight: FontWeight.w600,
        ),
      ),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: onToggle,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: AppMotion.of(context, AppMotion.fast),
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: tint.withValues(alpha: context.isDark ? 0.2 : 0.11),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: AnimatedSwitcher(
                    duration: AppMotion.of(context, AppMotion.fast),
                    child: Icon(
                      failed ? LucideIcons.circleAlert : words.icon,
                      key: ValueKey(failed),
                      size: 16,
                      color: tint,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpace.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (summary.isNotEmpty)
                        Text(
                          summary,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                            height: 1.35,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpace.xs),
                status,
                const SizedBox(width: 2),
                AnimatedRotation(
                  turns: open ? 0.5 : 0,
                  duration: AppMotion.of(context, AppMotion.fast),
                  child: Icon(
                    LucideIcons.chevronDown,
                    size: 18,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: AppMotion.of(context, const Duration(milliseconds: 220)),
          curve: AppMotion.curve,
          alignment: Alignment.topCenter,
          child: open
              ? _ToolDetails(entry: entry)
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}

class _ToolDetails extends StatelessWidget {
  const _ToolDetails({required this.entry});
  final ToolEntry entry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    final filePath = _toolFile(entry);
    final files = FileLinkScope.maybeOf(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(50, 0, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '${l10n.toolDetails}  ',
                        style: context.textTheme.labelMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      TextSpan(
                        text: entry.tool,
                        style: AppText.mono.copyWith(
                          fontSize: 11.5,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (filePath != null &&
                  files != null &&
                  entry.status == ToolStatus.done)
                TextButton.icon(
                  key: Key('openToolFile-${entry.callId}'),
                  onPressed: () => files.open(filePath),
                  icon: const Icon(LucideIcons.squareArrowOutUpRight, size: 16),
                  label: Text(l10n.openFileInChat),
                ),
            ],
          ),
          const SizedBox(height: 6),
          CodePanel(
            text: const JsonEncoder.withIndent('  ').convert(entry.args),
          ),
          if (entry.output.isNotEmpty) ...[
            const SizedBox(height: AppSpace.xs),
            Text(
              l10n.toolOutput,
              style: context.textTheme.labelMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            CodePanel(text: entry.output, maxHeight: 240, reverse: true),
          ],
          if (entry.preview != null && entry.output.isEmpty) ...[
            const SizedBox(height: AppSpace.xs),
            SelectableText(
              entry.preview!,
              style: context.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
          if (entry.error != null) ...[
            const SizedBox(height: AppSpace.xs),
            SelectableText(
              entry.error!,
              style: context.textTheme.bodySmall?.copyWith(
                color: context.appColors.negative,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// The file a tool step made or read, as a files API path (null when it isn't about a file).
String? _toolFile(ToolEntry t) {
  final artifact = t.artifactPath;
  if (artifact != null && artifact.isNotEmpty) {
    return computerPathFromLink(artifact);
  }
  if (!t.tool.startsWith('files.') ||
      t.tool == 'files.list' ||
      t.tool == 'files.search' ||
      t.tool == 'files.delete') {
    return null;
  }
  final p = t.args['path'];
  return p is String && p.isNotEmpty ? computerPathFromLink(p) : null;
}

/// "Details": the tool's name and exact arguments, folded away until asked for.
class _TechnicalDetails extends StatefulWidget {
  const _TechnicalDetails({required this.tool, required this.args});
  final String tool;
  final Map<String, Object?> args;

  @override
  State<_TechnicalDetails> createState() => _TechnicalDetailsState();
}

class _TechnicalDetailsState extends State<_TechnicalDetails> {
  var _open = false;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            key: const Key('approvalDetails'),
            // No side padding, so the chevron lines up with the text above it.
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 36),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: () => setState(() => _open = !_open),
            icon: AnimatedRotation(
              turns: _open ? 0.5 : 0,
              duration: AppMotion.of(context, AppMotion.fast),
              child: Icon(
                LucideIcons.chevronDown,
                size: 16,
                color: scheme.onSurfaceVariant,
              ),
            ),
            label: Text(
              context.l10n.toolDetails,
              style: context.textTheme.labelLarge?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
        AnimatedSize(
          duration: AppMotion.of(context, const Duration(milliseconds: 220)),
          curve: AppMotion.curve,
          alignment: Alignment.topCenter,
          child: _open
              ? Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        widget.tool,
                        style: AppText.mono.copyWith(
                          fontSize: 11.5,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      CodePanel(
                        text: const JsonEncoder.withIndent('  ')
                            .convert(widget.args),
                        maxLines: 8,
                        maxHeight: 180,
                      ),
                    ],
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}

/// Monospaced text on the code surface (arguments, output).
class CodePanel extends StatelessWidget {
  const CodePanel({
    super.key,
    required this.text,
    this.maxHeight = 200,
    this.reverse = false,
    this.maxLines,
  });
  final String text;
  final double maxHeight;
  final bool reverse;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: context.appColors.codeBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.appColors.hairline),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: SingleChildScrollView(
        primary: false,
        reverse: reverse,
        child: maxLines == null
            ? SelectableText(text, style: AppText.mono.copyWith(fontSize: 12.5))
            : Text(
                text,
                maxLines: maxLines,
                overflow: TextOverflow.ellipsis,
                style: AppText.mono.copyWith(fontSize: 12.5),
              ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------------------------
// Notices, approvals, takeovers

/// A short note in the thread (memory saved, checkpoint, computer state, run ended), centered.
class NoticeLine extends StatelessWidget {
  const NoticeLine({
    super.key,
    required this.entry,
    this.onRestore,
    this.onDetails,
    this.onUndo,
    this.plain = false,
    this.onRestartComputer,
    this.onFixComputer,
    this.personalComputer = false,
    this.onOpenMemory,
  });
  final NoticeEntry entry;

  /// "Remembered something": opens the bot's memory at what it saved.
  final VoidCallback? onOpenMemory;

  /// A computer that broke (state "error", D-240): restart it here, or open its fixes.
  final VoidCallback? onRestartComputer;

  /// The chat's computer is the person's own (D-447): when it can't be reached it is offline, not
  /// broken, and there is nothing to restart from here.
  final bool personalComputer;
  final VoidCallback? onFixComputer;

  /// "Saved to your profile" (D-169): takes the fact back out.
  final void Function(String factId)? onUndo;

  /// Simple chats (D-162): a failure without a plain explanation reads as one sentence; the
  /// technical part stays in Details.
  final bool plain;
  final void Function(String checkpointId)? onRestore;

  /// Failures open their details (error, failed steps, copy and export).
  final VoidCallback? onDetails;

  bool get _personalOffline =>
      personalComputer && entry.kind == NoticeKind.computer && const {'error', 'stopped', 'sleeping'}.contains(entry.text);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    final colors = context.appColors;
    final muted = scheme.onSurfaceVariant;
    final (icon, text, color) = switch (entry.kind) {
      NoticeKind.memory => (LucideIcons.brain, l10n.remembered, muted),
      NoticeKind.profileSaved => (
        LucideIcons.userRound,
        l10n.savedToProfile,
        muted,
      ),
      NoticeKind.skill => (
        LucideIcons.bookOpen,
        l10n.skillLoaded(entry.text),
        muted,
      ),
      NoticeKind.checkpoint => (
        LucideIcons.rotateCcw,
        l10n.checkpointSaved(entry.text),
        muted,
      ),
      NoticeKind.computer when _personalOffline => (
        LucideIcons.wifiOff,
        l10n.yourComputerOffline,
        colors.warning,
      ),
      NoticeKind.computer => (
        entry.text == 'error' ? LucideIcons.monitorX : LucideIcons.monitor,
        l10n.computerState(entry.text),
        entry.text == 'error' ? colors.negative : muted,
      ),
      NoticeKind.failed => (
        LucideIcons.circleAlert,
        plain && entry.text.startsWith(_genericFailure)
            ? l10n.runFailedPlain
            : l10n.runFailed(entry.text),
        colors.negative,
      ),
      NoticeKind.cancelled => (
        LucideIcons.circleStop,
        l10n.runCancelled,
        muted,
      ),
      NoticeKind.userControl => (
        LucideIcons.hand,
        l10n.pausedUserInControl,
        colors.warning,
      ),
      NoticeKind.botControl => (LucideIcons.bot, l10n.botBackInControl, muted),
      NoticeKind.modelFallback => (
        LucideIcons.arrowRightLeft,
        l10n.modelFallbackNotice(entry.text),
        colors.warning,
      ),
      NoticeKind.info => (LucideIcons.info, entry.text, colors.warning),
      NoticeKind.routine => (
        LucideIcons.alarmClock,
        l10n.routineRan(entry.text),
        muted,
      ),
    };
    final failed = entry.kind == NoticeKind.failed;
    final restorable =
        (entry.kind == NoticeKind.checkpoint && onRestore != null ||
            entry.kind == NoticeKind.profileSaved && onUndo != null) &&
        entry.refId != null;
    final details = failed && onDetails != null;
    final memory = entry.kind == NoticeKind.memory && onOpenMemory != null;
    final offline = _personalOffline && onFixComputer != null;
    final broken = !_personalOffline && entry.kind == NoticeKind.computer && entry.text == 'error' && (onRestartComputer != null || onFixComputer != null);
    return Center(
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          key: details ? const Key('errorDetails') : memory ? const Key('openMemory') : null,
          onTap: details ? onDetails : memory ? onOpenMemory : null,
          borderRadius: BorderRadius.circular(
            failed ? AppRadius.row : AppRadius.pill,
          ),
          child: Container(
            padding: EdgeInsets.fromLTRB(
              12,
              restorable || broken || offline ? 2 : 6,
              restorable || details || broken || offline ? 4 : memory ? 8 : 12,
              restorable || broken || offline ? 2 : 6,
            ),
            decoration: BoxDecoration(
              color: failed
                  ? colors.negative.withValues(alpha: 0.08)
                  : scheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(
                failed ? AppRadius.row : AppRadius.pill,
              ),
              border: Border.all(
                color: failed
                    ? colors.negative.withValues(alpha: 0.24)
                    : colors.hairline,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 15, color: color),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    text,
                    style: context.textTheme.labelMedium?.copyWith(
                      color: color,
                      height: 1.3,
                    ),
                  ),
                ),
                if (restorable && entry.kind == NoticeKind.profileSaved)
                  TextButton(
                    key: const Key('undoProfileFact'),
                    onPressed: () => onUndo!(entry.refId!),
                    child: Text(l10n.undo),
                  )
                else if (restorable)
                  TextButton(
                    onPressed: () => onRestore!(entry.refId!),
                    child: Text(l10n.restore),
                  ),
                if (broken && onRestartComputer != null)
                  TextButton(
                    key: const Key('noticeRestartComputer'),
                    onPressed: onRestartComputer,
                    child: Text(l10n.restartComputer),
                  ),
                if (broken && onFixComputer != null)
                  TextButton(
                    key: const Key('noticeMoreFixes'),
                    onPressed: onFixComputer,
                    child: Text(l10n.moreFixes),
                  ),
                if (offline)
                  TextButton(
                    key: const Key('noticeComputerOffline'),
                    onPressed: onFixComputer,
                    child: Text(l10n.howToFix),
                  ),
                if (memory) ...[
                  const SizedBox(width: 2),
                  Icon(LucideIcons.chevronRight, size: 16, color: color),
                ],
                if (details) ...[
                  const SizedBox(width: 6),
                  Text(
                    l10n.details,
                    style: context.textTheme.labelMedium?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Icon(LucideIcons.chevronRight, size: 16, color: color),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// An approval request where the bot paused: what it wants to do, and approve or deny right here.
class ApprovalPrompt extends ConsumerStatefulWidget {
  const ApprovalPrompt({super.key, required this.entry, required this.botName});
  final ApprovalEntry entry;
  final String botName;

  @override
  ConsumerState<ApprovalPrompt> createState() => _ApprovalPromptState();
}

class _ApprovalPromptState extends ConsumerState<ApprovalPrompt> {
  var _busy = false;
  String? _localDecision;

  /// "Don't ask again" is ticked: Allow becomes Always Allow. A choice you opt into above the
  /// buttons, never a third button under Allow where a slip would make it permanent.
  var _always = false;

  Future<void> _decide(bool approve, {bool always = false}) async {
    HapticFeedback.mediumImpact();
    // Allowing a high-risk request asks to unlock again (D-375).
    if (approve && widget.entry.risk == 'high' && (!await confirmIdentity(context, ref) || !mounted)) return;
    setState(() => _busy = true);
    final ok = await runGuarded(context, () async {
      await ref
          .read(backendProvider)
          .decideApproval(
            widget.entry.approvalId,
            approve: approve,
            alwaysAllow: always,
          );
      return true;
    });
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (ok == true) _localDecision = approve ? 'approved' : 'denied';
    });
    if (ok == true) {
      ref.invalidate(approvalsProvider);
      // The server marked its notification read; the inbox list catches up.
      ref.invalidate(notificationsProvider);
      unawaited(nudgeAfterAnswer(context, ref));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final e = widget.entry;
    final decision = e.decision ?? _localDecision;
    final high = e.risk == 'high';
    final words = toolWords(l10n, e.tool, e.args);
    // Once decided, the card folds into one quiet line: what it was and what you said.
    if (decision != null) {
      final (color, icon, line) = switch (decision) {
        'approved' => (
          colors.positive,
          LucideIcons.circleCheck,
          l10n.approvalAllowedLine(words.doing),
        ),
        'denied' => (
          colors.negative,
          LucideIcons.circleX,
          l10n.approvalDeclinedLine(words.doing),
        ),
        _ => (
          context.colorScheme.onSurfaceVariant,
          LucideIcons.clock,
          l10n.approvalExpiredLine(words.doing),
        ),
      };
      return _Folded(key: const Key('chatApproval'), text: line, color: color, icon: icon);
    }
    // Everyday words: what the bot wants to do, and what it's about. The command stays on the
    // card, because this is the moment someone decides; the raw request stays behind Details.
    final focus = words.detail ?? toolApprovalFocus(e.args);
    // An email, message or event shows as itself (D-337), so the person sees what they approve.
    final preview = approvalPreview(e.tool, e.args);
    return _ActionCard(
      key: const Key('chatApproval'),
      label: context.l10n.cardApproval,
      accent: high ? colors.negative : context.colorScheme.primary,
      icon: words.icon,
      title: words.doing,
      subtitle: l10n.approvalAsking(widget.botName),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (preview != null)
            preview
          else if (focus != null)
            Text(
              focus,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.bodyMedium?.copyWith(height: 1.4),
            ),
          if (high)
            Container(
              key: const Key('approvalRisk'),
              margin: EdgeInsets.only(top: focus != null ? AppSpace.sm : 0),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: colors.negative.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.triangleAlert, size: 16, color: colors.negative),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l10n.approvalLookClosely,
                      style: context.textTheme.labelLarge?.copyWith(color: colors.negative, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: AppSpace.xxs),
          _TechnicalDetails(tool: e.tool, args: e.args),
        ],
      ),
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _DontAskAgain(
            value: _always,
            label: l10n.approvalDontAskAgain(widget.botName),
            onChanged: _busy ? null : (v) => setState(() => _always = v),
          ),
          const SizedBox(height: AppSpace.sm),
          ActionButtons(
            actions: [
              OutlinedButton(
                key: const Key('chatDeny'),
                onPressed: _busy ? null : () => _decide(false),
                child: Text(l10n.notNow),
              ),
              GlowButton(
                key: const Key('chatApprove'),
                onPressed: _busy ? null : () => _decide(true, always: _always),
                child: AnimatedSwitcher(
                  duration: AppMotion.of(context, AppMotion.fast),
                  child: Text(_always ? l10n.alwaysAllow : l10n.allow, key: ValueKey(_always)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The "don't ask again" line above an approval's buttons: a checkbox and what it covers. The
/// whole line is the tap target.
class _DontAskAgain extends StatelessWidget {
  const _DontAskAgain({required this.value, required this.label, required this.onChanged});
  final bool value;
  final String label;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final onChanged = this.onChanged;
    return MergeSemantics(
      child: InkWell(
        key: const Key('chatAlwaysAllow'),
        onTap: onChanged == null ? null : () => onChanged(!value),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              SizedBox.square(
                dimension: 20,
                child: Checkbox(
                  value: value,
                  onChanged: onChanged == null ? null : (v) => onChanged(v ?? false),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: context.textTheme.bodyMedium?.copyWith(color: value ? scheme.onSurface : scheme.onSurfaceVariant),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A bot asking a person to take over its screen (a sign-in, a captcha).
class TakeoverPrompt extends StatelessWidget {
  const TakeoverPrompt({
    super.key,
    required this.entry,
    required this.botName,
    required this.onOpen,
  });
  final TakeoverEntry entry;
  final String botName;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    // Answered: one quiet line, like a decided approval.
    if (entry.outcome != null) {
      final done = entry.outcome == 'completed';
      return _Folded(
        key: const Key('chatTakeover'),
        text: switch (entry.outcome) {
          'completed' => l10n.takeoverHandedBackLine(entry.reason),
          'dismissed' => l10n.approvalDeclinedLine(entry.reason),
          _ => l10n.approvalExpiredLine(entry.reason),
        },
        color: done ? colors.positive : context.colorScheme.onSurfaceVariant,
        icon: done ? LucideIcons.circleCheck : LucideIcons.circleMinus,
      );
    }
    return _ActionCard(
      key: const Key('chatTakeover'),
      label: context.l10n.cardTakeover,
      accent: colors.info,
      icon: LucideIcons.hand,
      title: l10n.botNeedsHelp(botName),
      body: Text(
        entry.reason,
        style: context.textTheme.bodyMedium?.copyWith(height: 1.4),
      ),
      footer: ActionButtons(
        actions: [
          GlowButton.icon(
            key: const Key('chatTakeControl'),
            onPressed: onOpen,
            icon: const Icon(LucideIcons.monitorPlay, size: 18),
            label: Text(l10n.takeControl),
          ),
        ],
      ),
    );
  }
}

/// The protected card for a bot's secret request (D-101). The value goes from this field straight
/// to the API (and Vault); it is never put in the composer, drafts, messages or the bot's context.
class SecretPrompt extends ConsumerStatefulWidget {
  const SecretPrompt({super.key, required this.entry, required this.botName});
  final SecretEntry entry;
  final String botName;

  @override
  ConsumerState<SecretPrompt> createState() => _SecretPromptState();
}

class _SecretPromptState extends ConsumerState<SecretPrompt> {
  final _value = TextEditingController();
  var _obscure = true;
  var _busy = false;
  String? _sent;

  @override
  void initState() {
    super.initState();
    // The chat only learns an answer from the run's secret.resolved event, which a run that had
    // already ended never writes: ask the server, so an answered request doesn't stay open.
    if (widget.entry.outcome == null) unawaited(_refreshStatus());
  }

  Future<void> _refreshStatus() async {
    try {
      final status = await ref
          .read(backendProvider)
          .secretRequestStatus(widget.entry.requestId);
      if (mounted && status != 'pending' && _sent == null) {
        setState(() => _sent = status);
      }
    } catch (_) {
      // Offline: the card stays as it is, and answering says what happened.
    }
  }

  @override
  void dispose() {
    _value.clear();
    _value.dispose();
    super.dispose();
  }

  Future<void> _answer(bool save) async {
    final value = _value.text;
    if (save && value.trim().isEmpty) return;
    setState(() => _busy = true);
    final ok = await runGuarded(context, () async {
      final backend = ref.read(backendProvider);
      if (save) {
        await backend.fulfillSecretRequest(widget.entry.requestId, value);
      } else {
        await backend.declineSecretRequest(widget.entry.requestId);
      }
      return true;
    });
    _value.clear();
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (ok == true) _sent = save ? 'fulfilled' : 'declined';
    });
    // Answered elsewhere, or it ran out: show how it ended instead of an open card.
    if (ok != true) await _refreshStatus();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final e = widget.entry;
    final outcome = e.outcome ?? _sent;
    // Answered: one quiet line, like a decided approval. The reason and the field are done with.
    if (outcome != null) {
      final what = e.totp ? l10n.totpWhat(e.service) : l10n.secretWhat(e.service);
      final saved = outcome == 'fulfilled';
      return _Folded(
        key: const Key('chatSecret'),
        text: switch (outcome) {
          'fulfilled' => l10n.secretSaved(e.name),
          'declined' => l10n.approvalDeclinedLine(what),
          _ => l10n.approvalExpiredLine(what),
        },
        color: saved ? colors.positive : context.colorScheme.onSurfaceVariant,
        icon: saved ? LucideIcons.circleCheck : LucideIcons.circleMinus,
      );
    }
    // The secret's own name as the title, why the bot wants it under it, one filled field (D-256).
    return _ActionCard(
      key: const Key('chatSecret'),
      label: l10n.cardSecrets,
      accent: colors.warning,
      icon: LucideIcons.keyRound,
      title: e.totp ? l10n.totpRequestTitle(widget.botName, e.service) : e.name,
      subtitle: e.reason.isNotEmpty ? e.reason : l10n.secretRequestTitle(widget.botName, e.service),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpace.xs,
        children: [
          TextField(
            key: const Key('secretValue'),
            controller: _value,
            obscureText: _obscure,
            autocorrect: false,
            enableSuggestions: false,
            enableIMEPersonalizedLearning: false,
            keyboardType: TextInputType.visiblePassword,
            autofillHints: const <String>[],
            onChanged: (_) => setState(() {}),
            style: context.textTheme.bodyLarge,
            decoration: chatFieldDecoration(
              context,
              hint: e.totp ? '${e.name} · ${l10n.totpSeedLabel}' : e.name,
              suffix: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (e.totp) TotpScanButton(onScanned: (link) => setState(() => _value.text = link)),
                  IconButton(
                    tooltip: _obscure ? l10n.show : l10n.hide,
                    icon: Icon(_obscure ? LucideIcons.eye : LucideIcons.eyeOff, size: 20),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ],
              ),
            ),
            onSubmitted: (_) => _busy ? null : _answer(true),
          ),
          // Where it may be used, and that the bot never sees it.
          Text(
            '${l10n.secretRequestHosts(e.hosts.join(', '))}. ${e.totp ? l10n.totpSeedHelp : l10n.secretRequestHelp}',
            style: context.textTheme.bodySmall?.copyWith(color: context.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        spacing: AppSpace.xs,
        children: [
          TextButton(
            key: const Key('secretDecline'),
            onPressed: _busy ? null : () => _answer(false),
            child: Text(l10n.decline),
          ),
          FilledButton.tonal(
            key: const Key('secretSave'),
            onPressed: _busy || _value.text.trim().isEmpty ? null : () => _answer(true),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }
}

/// "Allow `<bot>` to use your calendar?" (D-149): one tap grants or skips; revoke in Settings.
class DeviceAccessPrompt extends ConsumerStatefulWidget {
  const DeviceAccessPrompt({
    super.key,
    required this.entry,
    required this.botName,
  });
  final DeviceAccessEntry entry;
  final String botName;

  @override
  ConsumerState<DeviceAccessPrompt> createState() => _DeviceAccessPromptState();
}

/// Allow cards the person answered Not Now, by run and kind, so the card a run's events bring back
/// after a relaunch stays folded instead of asking again.
const deviceAccessSkippedKey = 'casama.device_access_skipped';

class _DeviceAccessPromptState extends ConsumerState<DeviceAccessPrompt> {
  bool? _allowed;
  var _busy = false;

  String get _skipId => '${widget.entry.runId ?? ''}:${widget.entry.botId}:${widget.entry.kind.value}';

  @override
  void initState() {
    super.initState();
    unawaited(
      SharedPreferences.getInstance()
          .then((p) {
            if (mounted && (p.getStringList(deviceAccessSkippedKey) ?? const []).contains(_skipId)) {
              setState(() => _allowed ??= false);
            }
          })
          .catchError((_) {}),
    );
    // Already allowed (from an earlier card or Settings): show it as done.
    unawaited(
      ref
          .read(backendProvider)
          .deviceGrants(botId: widget.entry.botId, allKinds: true)
          .then((g) {
            if (mounted && g.any((x) => x.kind == widget.entry.kind)) {
              setState(() => _allowed ??= true);
            }
          })
          .catchError((_) {}),
    );
  }

  Future<void> _answer(bool allow) async {
    if (!allow) {
      setState(() => _allowed = false);
      try {
        final p = await SharedPreferences.getInstance();
        final skipped = p.getStringList(deviceAccessSkippedKey) ?? const <String>[];
        // The latest 100 are plenty: a card older than that is far up a chat.
        await p.setStringList(deviceAccessSkippedKey, [...skipped.where((x) => x != _skipId), _skipId].reversed.take(100).toList().reversed.toList());
      } catch (_) {}
      return;
    }
    setState(() => _busy = true);
    final ok = await runGuarded(context, () async {
      await ref
          .read(backendProvider)
          .setDeviceGrant(widget.entry.botId, widget.entry.kind, true);
      return true;
    });
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (ok == true) _allowed = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final e = widget.entry;
    final what = deviceKindLabel(l10n, e.kind);
    // Answered: one quiet line, like a decided approval.
    if (_allowed != null) {
      return _Folded(
        key: const Key('chatDeviceAccess'),
        text: _allowed! ? l10n.deviceAccessAllowed(what) : l10n.deviceAccessSkippedLine(what),
        color: _allowed! ? colors.positive : context.colorScheme.onSurfaceVariant,
        icon: _allowed! ? LucideIcons.circleCheck : LucideIcons.circleMinus,
      );
    }
    return _ActionCard(
      key: const Key('chatDeviceAccess'),
      label: context.l10n.cardDevice,
      accent: colors.working,
      icon: LucideIcons.smartphone,
      title: l10n.deviceAccessTitle(widget.botName, what),
      subtitle: l10n.deviceAccessHelp,
      body: e.reason.isEmpty
          ? const SizedBox.shrink()
          : Text(
              e.reason,
              style: context.textTheme.bodyMedium?.copyWith(height: 1.4),
            ),
      footer: ActionButtons(
              actions: [
                OutlinedButton(
                  key: const Key('deviceAccessSkip'),
                  onPressed: _busy ? null : () => _answer(false),
                  child: Text(l10n.notNow),
                ),
                GlowButton.icon(
                  key: const Key('deviceAccessAllow'),
                  onPressed: _busy ? null : () => _answer(true),
                  icon: const Icon(LucideIcons.check, size: 18),
                  label: Text(l10n.allow),
                ),
              ],
            ),
    );
  }
}

/// The workspace's paired computers, to name the one a sign-in card is about.
final _pairedDevicesProvider = FutureProvider.autoDispose<List<LocalDevice>>((ref) {
  final org = ref.watch(currentOrgProvider);
  return org == null ? Future.value(const <LocalDevice>[]) : ref.watch(backendProvider).localDevices(org.id);
});

/// A local MCP server whose sign-in ran out (D-363). On that computer: a Sign in button that
/// opens the browser; anywhere else, which computer to sign in on.
class McpSignInPrompt extends ConsumerStatefulWidget {
  const McpSignInPrompt({super.key, required this.entry});
  final McpSignInEntry entry;

  @override
  ConsumerState<McpSignInPrompt> createState() => _McpSignInPromptState();
}

class _McpSignInPromptState extends ConsumerState<McpSignInPrompt> {
  var _busy = false;
  var _done = false;

  Future<void> _signIn() async {
    setState(() => _busy = true);
    final ok = await runGuarded(context, () async {
      await ref.read(companionControllerProvider.notifier).signInMcpServer(widget.entry.server);
      return true;
    });
    if (!mounted) return;
    setState(() {
      _busy = false;
      _done = ok == true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final e = widget.entry;
    if (_done) {
      return _Folded(key: const Key('chatMcpSignIn'), text: l10n.localMcpSignedIn(e.label), color: colors.positive, icon: LucideIcons.circleCheck);
    }
    final here = ref.watch(companionControllerProvider).value?.id == e.deviceId;
    final device = ref.watch(_pairedDevicesProvider).value?.where((d) => d.id == e.deviceId).firstOrNull?.name;
    return _ActionCard(
      key: const Key('chatMcpSignIn'),
      label: l10n.cardMcpSignIn,
      accent: colors.warning,
      icon: LucideIcons.logIn,
      title: l10n.mcpSignInTitle(e.label),
      subtitle: here ? l10n.mcpSignInHereHelp : l10n.mcpSignInElsewhereHelp(device ?? l10n.localMcpServers),
      body: const SizedBox.shrink(),
      footer: here
          ? ActionButtons(
              actions: [
                GlowButton.icon(
                  key: const Key('mcpSignIn'),
                  onPressed: _busy ? null : _signIn,
                  icon: const Icon(LucideIcons.logIn, size: 18),
                  label: Text(l10n.localMcpSignIn),
                ),
              ],
            )
          : const SizedBox.shrink(),
    );
  }
}

/// One field of an MCP question's form (the spec keeps it flat, D-363).
class _QuestionField {
  _QuestionField(this.name, Map<String, Object?> p, this.required)
      : type = (p['type'] as String?) ?? (p['enum'] != null || p['oneOf'] != null ? 'string' : ''),
        title = p['title'] as String?,
        description = p['description'] as String?,
        options = p['enum'] is List
            ? [for (final v in p['enum'] as List) '$v']
            : p['oneOf'] is List
                ? [for (final o in p['oneOf'] as List) if (o is Map) '${o['const']}']
                : null,
        optionLabels = p['enumNames'] is List
            ? [for (final v in p['enumNames'] as List) '$v']
            : p['oneOf'] is List
                ? [for (final o in p['oneOf'] as List) if (o is Map) '${o['title'] ?? o['const']}']
                : null,
        initial = p['default'];
  final String name;
  final String type;
  final bool required;
  final String? title;
  final String? description;
  final List<String>? options;
  final List<String>? optionLabels;
  final Object? initial;

  static List<_QuestionField>? from(Map<String, Object?> schema) {
    final props = schema['properties'];
    if (props is! Map) return schema['properties'] == null ? const [] : null;
    final req = {for (final r in (schema['required'] as List? ?? const [])) '$r'};
    final out = <_QuestionField>[];
    for (final e in props.entries) {
      if (e.value is! Map) return null;
      final f = _QuestionField('${e.key}', Map<String, Object?>.from(e.value as Map), req.contains('${e.key}'));
      if (!const {'string', 'number', 'integer', 'boolean'}.contains(f.type)) return null;
      out.add(f);
    }
    return out;
  }
}

/// Questions answered from this app, by id: a chat row can be rebuilt before the run's own
/// "resolved" event arrives, and the card mustn't ask again.
class AnsweredMcpQuestions extends Notifier<Map<String, String>> {
  @override
  Map<String, String> build() => const {};

  void answered(String id, String outcome) => state = {...state, id: outcome};
}

final answeredMcpQuestionsProvider = NotifierProvider<AnsweredMcpQuestions, Map<String, String>>(AnsweredMcpQuestions.new);

/// A connected MCP server's question (MCP elicitation, D-363): its form, Send or Decline. The
/// bot's call waits for the answer.
class McpQuestionPrompt extends ConsumerStatefulWidget {
  const McpQuestionPrompt({super.key, required this.entry});
  final McpQuestionEntry entry;

  @override
  ConsumerState<McpQuestionPrompt> createState() => _McpQuestionPromptState();
}

class _McpQuestionPromptState extends ConsumerState<McpQuestionPrompt> {
  late final List<_QuestionField> _fields = _QuestionField.from(widget.entry.schema) ?? const [];
  final _text = <String, TextEditingController>{};
  final _values = <String, Object?>{};
  var _busy = false;

  @override
  void initState() {
    super.initState();
    for (final f in _fields) {
      if (f.type == 'boolean') {
        _values[f.name] = f.initial is bool ? f.initial : false;
      } else if (f.options != null) {
        _values[f.name] = f.initial != null && f.options!.contains('${f.initial}') ? '${f.initial}' : null;
      } else {
        _text[f.name] = TextEditingController(text: f.initial == null ? '' : '${f.initial}');
      }
    }
  }

  @override
  void dispose() {
    for (final c in _text.values) {
      c.dispose();
    }
    super.dispose();
  }

  Map<String, Object?> _content() => {
        for (final f in _fields)
          if (f.type == 'boolean' || f.options != null)
            if (_values[f.name] != null) f.name: _values[f.name] else ...{}
          else if (_text[f.name]!.text.trim().isNotEmpty)
            f.name: switch (f.type) {
              'integer' => int.tryParse(_text[f.name]!.text.trim()) ?? _text[f.name]!.text.trim(),
              'number' => num.tryParse(_text[f.name]!.text.trim()) ?? _text[f.name]!.text.trim(),
              _ => _text[f.name]!.text,
            },
      };

  bool get _complete => _fields.every((f) => !f.required || _content().containsKey(f.name));

  Future<void> _answer(String action) async {
    setState(() => _busy = true);
    final ok = await runGuarded(context, () async {
      await ref.read(backendProvider).answerMcpQuestion(widget.entry.questionId, action, action == 'accept' ? _content() : null);
      return true;
    });
    if (!mounted) return;
    if (ok == true) ref.read(answeredMcpQuestionsProvider.notifier).answered(widget.entry.questionId, action == 'accept' ? 'accepted' : 'declined');
    setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final e = widget.entry;
    final outcome = e.outcome ?? ref.watch(answeredMcpQuestionsProvider)[e.questionId];
    if (outcome != null) {
      return _Folded(
        key: const Key('chatMcpQuestion'),
        text: switch (outcome) {
          'accepted' => l10n.mcpQuestionAnswered(e.connection),
          'declined' => l10n.mcpQuestionDeclined(e.connection),
          _ => l10n.mcpQuestionClosed(e.connection),
        },
        color: outcome == 'accepted' ? colors.positive : context.colorScheme.onSurfaceVariant,
        icon: outcome == 'accepted' ? LucideIcons.circleCheck : LucideIcons.circleMinus,
      );
    }
    return _ActionCard(
      key: const Key('chatMcpQuestion'),
      label: l10n.cardMcpQuestion,
      accent: colors.working,
      icon: LucideIcons.messageCircleQuestion,
      title: l10n.mcpQuestionTitle(e.connection),
      subtitle: e.message,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpace.xs,
        children: [
          for (final f in _fields)
            if (f.type == 'boolean')
              // Its own Material: the card's background would hide the tile's ink.
              Material(
                type: MaterialType.transparency,
                child: SwitchListTile(
                  key: Key('mcpField-${f.name}'),
                  contentPadding: EdgeInsets.zero,
                  title: Text(f.title ?? f.name),
                  subtitle: f.description == null ? null : Text(f.description!),
                  value: _values[f.name] == true,
                  onChanged: (v) => setState(() => _values[f.name] = v),
                ),
              )
            else if (f.options != null)
              DropdownButtonFormField<String>(
                key: Key('mcpField-${f.name}'),
                initialValue: _values[f.name] as String?,
                decoration: InputDecoration(labelText: f.title ?? f.name, helperText: f.description),
                items: [
                  for (var i = 0; i < f.options!.length; i++)
                    DropdownMenuItem(value: f.options![i], child: Text(f.optionLabels != null && i < f.optionLabels!.length ? f.optionLabels![i] : f.options![i])),
                ],
                onChanged: (v) => setState(() => _values[f.name] = v),
              )
            else
              TextField(
                key: Key('mcpField-${f.name}'),
                controller: _text[f.name],
                keyboardType: f.type == 'string' ? TextInputType.text : const TextInputType.numberWithOptions(decimal: true, signed: true),
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(labelText: f.title ?? f.name, helperText: f.description),
              ),
        ],
      ),
      footer: ActionButtons(
        actions: [
          OutlinedButton(
            key: const Key('mcpQuestionDecline'),
            onPressed: _busy ? null : () => _answer('decline'),
            child: Text(l10n.mcpQuestionDecline),
          ),
          GlowButton.icon(
            key: const Key('mcpQuestionSend'),
            onPressed: _busy || !_complete ? null : () => _answer('accept'),
            icon: const Icon(LucideIcons.send, size: 18),
            label: Text(l10n.mcpQuestionSend),
          ),
        ],
      ),
    );
  }
}

/// An answered request (approval, key, takeover, device access) folded into one quiet line.
class _Folded extends StatelessWidget {
  const _Folded({super.key, required this.text, required this.color, required this.icon});
  final String text;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4),
    child: _Outcome(text: text, color: color, icon: icon),
  );
}

class _Outcome extends StatelessWidget {
  const _Outcome({required this.text, required this.color, required this.icon});
  final String text;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 18, color: color),
      const SizedBox(width: 6),
      Flexible(
        child: Text(
          text,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: context.textTheme.labelLarge?.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    ],
  ).appCardEntrance();
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    super.key,
    required this.label,
    required this.accent,
    required this.icon,
    required this.title,
    required this.body,
    required this.footer,
    this.subtitle,
  });

  /// What kind of request it is ("Secrets", "Approval"), beside the icon.
  final String label;
  final Color accent;
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget body;
  final Widget footer;

  /// A card in the chat's look (D-256): the kind in a small header, a bold title, grey help text,
  /// then what to fill in or decide.
  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    return Container(
      padding: ChatLook.cardPadding,
      decoration: ChatLook.card(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(color: ChatLook.fieldFill(context), borderRadius: BorderRadius.circular(9)),
                alignment: Alignment.center,
                child: Icon(icon, size: 17, color: accent),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(title, style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, height: 1.3)),
          if (subtitle != null && subtitle!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(subtitle!, style: context.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant, height: 1.4)),
            ),
          const SizedBox(height: 14),
          body,
          const SizedBox(height: 14),
          footer,
        ],
      ),
    );
  }
}

/// A filled field inside a chat card (D-256): no outline, rounded, the hint in grey.
InputDecoration chatFieldDecoration(BuildContext context, {String? hint, Widget? suffix}) => InputDecoration(
  hintText: hint,
  filled: true,
  fillColor: ChatLook.fieldFill(context),
  isDense: true,
  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: BorderSide(color: context.colorScheme.primary.withValues(alpha: 0.6)),
  ),
  suffixIcon: suffix,
);

/// A suggestion the bot posted in General (D-253): Do it opens a topic where the bot does it;
/// Not now dismisses it. Once handled, a quiet line (with a link to the topic it opened).
class SuggestionPrompt extends ConsumerStatefulWidget {
  const SuggestionPrompt({
    super.key,
    required this.entry,
    required this.botId,
    required this.botName,
    required this.onOpenTopic,
  });
  final SuggestionEntry entry;
  final String botId;
  final String botName;
  final ValueChanged<String> onOpenTopic;

  @override
  ConsumerState<SuggestionPrompt> createState() => _SuggestionPromptState();
}

class _SuggestionPromptState extends ConsumerState<SuggestionPrompt> {
  var _busy = false;

  /// Answered here, before the lists that say so reload.
  bool? _accepted;

  /// The topic Do it started here.
  String? _topic;

  Future<void> _accept() async {
    setState(() => _busy = true);
    final r = await runGuarded(context, () => ref.read(backendProvider).acceptSuggestion(widget.entry.suggestion.id));
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (r != null) {
        _accepted = true;
        _topic = r.conversationId;
      }
    });
    ref.invalidate(forYouProvider);
    ref.invalidate(conversationsProvider(widget.botId));
    if (r != null) widget.onOpenTopic(r.conversationId);
  }

  Future<void> _dismiss() async {
    setState(() => _busy = true);
    final ok = await runGuarded(context, () async {
      await ref.read(backendProvider).dismissSuggestion(widget.entry.suggestion.id);
      return true;
    });
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (ok == true) _accepted = false;
    });
    ref.invalidate(forYouProvider);
  }

  // Its status loads after the card shows: going from the full card to its one-line summary
  // resizes and cross-fades instead of snapping.
  @override
  Widget build(BuildContext context) => AnimatedSize(
    duration: AppMotion.of(context, AppMotion.duration),
    curve: AppMotion.curve,
    alignment: AlignmentDirectional.topStart,
    child: AnimatedSwitcher(duration: AppMotion.of(context, AppMotion.fast), child: _content(context)),
  );

  Widget _content(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final s = widget.entry.suggestion;
    final open = ref.watch(forYouProvider).value?.suggestions;
    // For you lists at most 30; a full list can't say a missing one is closed.
    final pending = open == null || open.length >= 30 ? null : open.map((x) => x.id).toSet();
    // The topic this card opened, when it was accepted.
    final state = ref.watch(suggestionStatesProvider(s.id)).value?[s.id];
    final anchored = (ref.watch(conversationsProvider(widget.botId)).value ?? const <Conversation>[])
        .where((c) => c.anchorMessageId == widget.entry.messageId)
        .firstOrNull;
    final topic = _topic ?? state?.conversationId ?? anchored?.id;
    final handled = _accepted != null ||
        topic != null ||
        (state != null ? !state.open : pending != null && !pending.contains(s.id));
    if (handled) {
      if (topic != null || _accepted == true || state?.status == SuggestionStatus.accepted) {
        return Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            key: Key('suggestionTopic-${s.id}'),
            icon: Icon(LucideIcons.messagesSquare, size: 16, color: colors.positive),
            label: Text(l10n.suggestionInTopic(s.title), maxLines: 1, overflow: TextOverflow.ellipsis),
            onPressed: topic == null ? null : () => widget.onOpenTopic(topic),
          ),
        );
      }
      return _Folded(
        key: Key('suggestionDone-${s.id}'),
        text: _accepted == null && state?.status == SuggestionStatus.expired
            ? l10n.suggestionExpiredTitle(s.title)
            : l10n.suggestionClosed(s.title),
        color: context.colorScheme.onSurfaceVariant,
        icon: LucideIcons.circleMinus,
      );
    }
    return _ActionCard(
      key: Key('suggestionCard-${s.id}'),
      label: context.l10n.cardSuggestion,
      accent: colors.working,
      icon: LucideIcons.sparkles,
      title: s.title,
      body: s.body.trim().isEmpty
          ? const SizedBox.shrink()
          : InkWell(
              key: Key('suggestionMore-${s.id}'),
              borderRadius: BorderRadius.circular(8),
              onTap: _busy
                  ? null
                  : () => showSuggestionDetail(context, s, onDoIt: _accept, onNotNow: _dismiss),
              child: Text(s.body.trim(), maxLines: 2, overflow: TextOverflow.ellipsis, style: context.textTheme.bodyMedium?.copyWith(height: 1.4)),
            ),
      footer: ActionButtons(
        actions: [
          OutlinedButton(
            key: Key('suggestionNotNow-${s.id}'),
            onPressed: _busy ? null : _dismiss,
            child: Text(l10n.notNow),
          ),
          GlowButton.icon(
            key: Key('suggestionDoIt-${s.id}'),
            onPressed: _busy ? null : _accept,
            icon: const Icon(LucideIcons.check, size: 18),
            label: Text(l10n.doIt),
          ),
        ],
      ),
    );
  }
}

/// A topic's result posted back to General (D-253): its title, tappable into the topic.
class TopicLinkLine extends StatelessWidget {
  const TopicLinkLine({super.key, required this.entry, required this.onOpen});
  final TopicLinkEntry entry;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final title = entry.topic.title.trim().isEmpty ? context.l10n.untitledChat : entry.topic.title.trim();
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: ActionChip(
        key: Key('topicLink-${entry.topic.conversationId}'),
        avatar: Icon(LucideIcons.messagesSquare, size: 16, color: scheme.primary),
        label: Text(context.l10n.openTopic(title), maxLines: 1, overflow: TextOverflow.ellipsis),
        onPressed: onOpen,
      ),
    );
  }
}


/// Several suggestions in one card (D-257): each open row has its own Do it, and opens the whole
/// suggestion with Do it and Not now; the card's Not now puts away the rest. Answered rows say what
/// happened, and a started one opens its topic. Once all are answered, one line.
class SuggestionListPrompt extends ConsumerStatefulWidget {
  const SuggestionListPrompt({super.key, required this.entry, required this.botId, required this.onOpenTopic});
  final SuggestionListEntry entry;
  final String botId;
  final ValueChanged<String> onOpenTopic;

  @override
  ConsumerState<SuggestionListPrompt> createState() => _SuggestionListPromptState();
}

class _SuggestionListPromptState extends ConsumerState<SuggestionListPrompt> {
  /// Answered here, before the statuses reload.
  final _local = <String, SuggestionState>{};

  /// The suggestion being started, or '*' while the rest are put away.
  String? _busy;

  Future<void> _accept(MessageSuggestion s) async {
    setState(() => _busy = s.id);
    final r = await runGuarded(context, () => ref.read(backendProvider).acceptSuggestion(s.id));
    if (!mounted) return;
    setState(() {
      _busy = null;
      if (r != null) {
        _local[s.id] = SuggestionState(status: SuggestionStatus.accepted, resolvedAt: DateTime.now(), conversationId: r.conversationId);
      }
    });
    ref.invalidate(forYouProvider);
    ref.invalidate(conversationsProvider(widget.botId));
    if (r != null) widget.onOpenTopic(r.conversationId);
  }

  Future<void> _dismiss(List<MessageSuggestion> items) async {
    setState(() => _busy = '*');
    await runGuarded(context, () async {
      for (final s in items) {
        await ref.read(backendProvider).dismissSuggestion(s.id);
        _local[s.id] = SuggestionState(status: SuggestionStatus.dismissed, resolvedAt: DateTime.now());
      }
      return true;
    });
    if (!mounted) return;
    setState(() => _busy = null);
    ref.invalidate(forYouProvider);
  }

  // Its status loads after the card shows: going from the full card to its one-line summary
  // resizes and cross-fades instead of snapping.
  @override
  Widget build(BuildContext context) => AnimatedSize(
    duration: AppMotion.of(context, AppMotion.duration),
    curve: AppMotion.curve,
    alignment: AlignmentDirectional.topStart,
    child: AnimatedSwitcher(duration: AppMotion.of(context, AppMotion.fast), child: _content(context)),
  );

  Widget _content(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final scheme = context.colorScheme;
    final items = widget.entry.items;
    final states = ref.watch(suggestionStatesProvider(items.map((s) => s.id).join(','))).value;
    // Until the statuses load, For you says which are still open (it lists at most 30, so a full
    // list can't say a missing one is closed).
    final listed = ref.watch(forYouProvider).value?.suggestions;
    final pending = listed == null || listed.length >= 30 ? null : listed.map((x) => x.id).toSet();
    SuggestionState? stateOf(MessageSuggestion s) => _local[s.id] ?? states?[s.id];
    bool open(MessageSuggestion s) =>
        stateOf(s)?.open ?? (pending == null || pending.contains(s.id));
    final waiting = items.where(open).toList();
    if (waiting.isEmpty) {
      final started = [
        for (final s in items)
          if (stateOf(s)?.conversationId case final String topic) (s, topic),
      ];
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Folded(
            key: Key('suggestionsDone-${widget.entry.messageId}'),
            text: l10n.suggestionsHandled(items.length),
            color: scheme.onSurfaceVariant,
            icon: LucideIcons.circleCheck,
          ),
          for (final (s, topic) in started)
            TextButton.icon(
              key: Key('suggestionTopic-${s.id}'),
              icon: Icon(LucideIcons.messagesSquare, size: 16, color: colors.positive),
              label: Text(l10n.suggestionInTopic(s.title), maxLines: 1, overflow: TextOverflow.ellipsis),
              onPressed: () => widget.onOpenTopic(topic),
            ),
        ],
      );
    }
    return _ActionCard(
      key: Key('suggestionList-${widget.entry.messageId}'),
      label: l10n.cardSuggestions,
      accent: colors.working,
      icon: LucideIcons.sparkles,
      title: l10n.suggestionsTitle(items.length),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpace.xs,
        children: [for (final s in items) _row(context, s, stateOf(s), open(s))],
      ),
      footer: Align(
        alignment: AlignmentDirectional.centerEnd,
        child: TextButton(
          key: Key('suggestionsNotNow-${widget.entry.messageId}'),
          onPressed: _busy != null ? null : () => _dismiss(waiting),
          child: Text(l10n.notNow),
        ),
      ),
    );
  }

  Widget _row(BuildContext context, MessageSuggestion s, SuggestionState? state, bool open) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    final topic = open ? null : state?.conversationId;
    final status = open ? null : suggestionStatus(context, state);
    return Material(
      key: Key('suggestionRow-${s.id}'),
      color: ChatLook.fieldFill(context),
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        // A started one opens its topic; the rest open the whole suggestion, which the row cuts short.
        onTap: topic != null
            ? () => widget.onOpenTopic(topic)
            : () => showSuggestionDetail(
                context,
                s,
                onDoIt: open && _busy == null ? () => _accept(s) : null,
                onNotNow: open && _busy == null ? () => _dismiss([s]) : null,
                status: status?.text,
              ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: open ? null : scheme.onSurfaceVariant,
                      ),
                    ),
                    if (status != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Row(
                          key: Key('suggestionStatus-${s.id}'),
                          spacing: 4,
                          children: [
                            Icon(status.icon, size: 14, color: status.color),
                            Flexible(
                              child: Text(
                                status.text,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: context.textTheme.bodySmall?.copyWith(color: status.color),
                              ),
                            ),
                          ],
                        ),
                      )
                    else if (open && s.body.trim().isNotEmpty)
                      Text(s.body.trim(), maxLines: 1, overflow: TextOverflow.ellipsis, style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                  ],
                ),
              ),
              const SizedBox(width: AppSpace.xs),
              if (open)
                FilledButton.tonal(
                  key: Key('suggestionRowDoIt-${s.id}'),
                  onPressed: _busy == null ? () => _accept(s) : null,
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: AppSpace.md),
                  ),
                  child: _busy == s.id
                      ? const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(l10n.doIt),
                )
              else if (topic != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpace.xs),
                  child: Icon(LucideIcons.chevronRight, size: 18, color: scheme.onSurfaceVariant),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// What happened to an answered suggestion, in a few words: started (when), put away, or expired.
/// Null while that isn't known yet.
({String text, IconData icon, Color color})? suggestionStatus(BuildContext context, SuggestionState? state) {
  final l10n = context.l10n;
  final muted = context.colorScheme.onSurfaceVariant;
  String when(DateTime t) {
    final local = t.toLocal();
    final now = DateTime.now();
    final today = local.year == now.year && local.month == now.month && local.day == now.day;
    return today ? local.formattedTime(context) : local.formattedDate(context);
  }

  return switch (state?.status) {
    SuggestionStatus.accepted => (
      text: state!.resolvedAt == null ? l10n.suggestionStartedPlain : l10n.suggestionStarted(when(state.resolvedAt!)),
      icon: LucideIcons.circleCheck,
      color: context.appColors.positive,
    ),
    SuggestionStatus.dismissed => (text: l10n.suggestionPutAway, icon: LucideIcons.circleMinus, color: muted),
    SuggestionStatus.expired => (text: l10n.suggestionExpired, icon: LucideIcons.clock, color: muted),
    _ => null,
  };
}

/// A suggestion in full (its title and everything the bot wrote), opened from its card or row, with
/// Do it and Not now when it's still open. Null callbacks mean it was answered: the sheet says how
/// ([status]) and only reads.
Future<void> showSuggestionDetail(
  BuildContext context,
  MessageSuggestion s, {
  required VoidCallback? onDoIt,
  required VoidCallback? onNotNow,
  String? status,
}) {
  final open = onDoIt != null;
  return showAdaptiveSheet<void>(
    context: context,
    builder: (sheet) {
      final l10n = sheet.l10n;
      void then(VoidCallback? action) {
        Navigator.of(sheet).pop();
        action?.call();
      }

      return FormSheet(
        key: Key('suggestionDetail-${s.id}'),
        icon: LucideIcons.sparkles,
        iconColor: sheet.appColors.working,
        title: s.title,
        submitLabel: open ? l10n.doIt : MaterialLocalizations.of(sheet).closeButtonLabel,
        submitIcon: open ? LucideIcons.check : null,
        submitKey: Key('suggestionDetailDoIt-${s.id}'),
        onSubmit: () => then(onDoIt),
        showCancel: open,
        cancelLabel: l10n.notNow,
        onCancel: () => then(onNotNow),
        children: [
          if (s.body.trim().isNotEmpty)
            SelectableText(s.body.trim(), style: sheet.textTheme.bodyLarge?.copyWith(height: 1.5)),
          if (!open && status != null) ...[
            const SizedBox(height: AppSpace.md),
            Text(
              status,
              key: Key('suggestionDetailStatus-${s.id}'),
              style: sheet.textTheme.labelLarge?.copyWith(color: sheet.colorScheme.onSurfaceVariant),
            ),
          ],
        ],
      );
    },
  );
}
