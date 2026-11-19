import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/analytics.dart';
import '../../core/backend.dart';
import '../../core/haptics.dart';
import '../../core/providers.dart';
import '../../core/share.dart';
import '../../core/widgets.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../ui/adaptive_modal.dart';
import '../chat/chat_controller.dart' show CallRecapEntry, CallTurnView;
import 'active_call.dart';
import 'call_bubble.dart' show CallTimerText, callClock, callScreenPath;

/// A long transcript opens in a sheet instead of unfolding inline, so the chat doesn't jump.
const callTranscriptInlineMax = 40;

/// How long a card shows "Writing a summary…" before it gives up waiting quietly.
const callSummaryPatience = Duration(seconds: 45);

/// A call as one card in its chat (D-327 §8, call card plan): what it was about, what's left to
/// do (one tap each), what was done on it, its transcript folded in, and a way to call back. While
/// the call goes on it's a live card that becomes the finished one in place.
class CallCard extends ConsumerStatefulWidget {
  const CallCard({
    super.key,
    required this.entry,
    required this.botId,
    required this.botName,
    required this.conversationId,
    required this.onOpenRun,
    required this.onOpenPath,
    required this.onStep,
    required this.onCallBack,
    required this.onDelete,
  });

  final CallRecapEntry entry;
  final String botId;
  final String botName;
  final String? conversationId;
  final ValueChanged<String> onOpenRun;
  final ValueChanged<String> onOpenPath;

  /// Starts a next step as a chat run, or dismisses it.
  final Future<void> Function(String liveCallId, String stepId, {bool dismiss})
  onStep;
  final VoidCallback onCallBack;
  final Future<void> Function(String liveCallId) onDelete;

  @override
  ConsumerState<CallCard> createState() => _CallCardState();
}

class _CallCardState extends ConsumerState<CallCard> {
  var _transcriptOpen = false;
  var _summaryOpen = false;
  var _allDone = false;
  final _busySteps = <String>{};
  Timer? _patience;

  MessageCall? get _call => widget.entry.call;

  @override
  void initState() {
    super.initState();
    _armPatience();
  }

  @override
  void didUpdateWidget(CallCard old) {
    super.didUpdateWidget(old);
    if (old.entry.call?.summaryStatus != _call?.summaryStatus) _armPatience();
  }

  /// A summary still pending long after the call is treated as none (the job died).
  void _armPatience() {
    _patience?.cancel();
    final c = _call;
    if (c == null || !c.summaryPending) return;
    final since = DateTime.now().difference(
      c.endedAt ?? widget.entry.at ?? DateTime.now(),
    );
    final left = callSummaryPatience - since;
    if (left <= Duration.zero) return;
    _patience = Timer(left, () {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _patience?.cancel();
    super.dispose();
  }

  bool get _waitingForSummary {
    final c = _call;
    if (c == null || !c.summaryPending) return false;
    final since = DateTime.now().difference(
      c.endedAt ?? widget.entry.at ?? DateTime.now(),
    );
    return since < callSummaryPatience;
  }

  /// This device's call, when the card is for it and it's still going on.
  CallController? _liveHere(ActiveCall active) {
    final live = active.live;
    final id = widget.entry.liveCallId;
    if (live == null || id == null || live.liveCallId != id) return null;
    return live.over ? null : live;
  }

  /// No card yet, but the last turn is recent: a call going on on another device.
  bool get _liveElsewhere {
    if (_call != null) return false;
    final at = widget.entry.at;
    return at != null &&
        DateTime.now().difference(at) < const Duration(minutes: 3);
  }

  String _title(BuildContext context) {
    final l10n = context.l10n;
    final c = _call;
    if (c == null) return l10n.callCardVoice(callClock(_turnSpan()));
    final length = callClock(Duration(seconds: c.seconds));
    if (c.missed) return l10n.callCardMissed(widget.botName);
    if (c.ended == 'dropped') return l10n.callCardDropped(length);
    return c.kind == 'phone'
        ? l10n.callCardPhone(length)
        : l10n.callCardVoice(length);
  }

  /// A call with no card yet: as long as its turns span.
  Duration _turnSpan() {
    final t = widget.entry.turns;
    if (t.length < 2) return Duration.zero;
    return t.last.at.difference(t.first.at);
  }

  /// "2:41 PM · Nova hung up": when it ended, and how when that's worth saying.
  String _subtitle(BuildContext context) {
    final l10n = context.l10n;
    final c = _call;
    final at = c?.endedAt ?? widget.entry.at;
    final parts = <String>[
      if (at != null)
        MaterialLocalizations.of(context)
            .formatTimeOfDay(TimeOfDay.fromDateTime(at)),
      if (c != null)
        switch (c.ended) {
          'bot_hung_up' => l10n.callCardBotHungUp(widget.botName),
          'idle' || 'silent' => l10n.callCardEndedQuiet,
          'limit' => l10n.callCardEndedLimit,
          _ => '',
        },
    ];
    return parts.where((p) => p.isNotEmpty).join(' · ');
  }

  /// The whole call as plain text: for Copy and Share.
  String _asText(BuildContext context) {
    final l10n = context.l10n;
    final c = _call;
    final lines = <String>[_title(context)];
    if (c?.summary case final s? when s.isNotEmpty) lines.add(s);
    if (c?.reason case final r? when r.isNotEmpty) lines.add(r);
    final steps = c?.openSteps ?? const <MessageCallStep>[];
    if (steps.isNotEmpty) {
      lines
        ..add('')
        ..add('${l10n.callCardNextSteps}:')
        ..addAll(steps.map((s) => '- ${s.label}'));
    }
    final done = [
      ...?c?.tasks.map((t) => t.task),
      ...?c?.actions.where((a) => a.ok).map((a) => a.label),
    ];
    if (done.isNotEmpty) {
      lines
        ..add('')
        ..add('${l10n.callCardDoneOnCall}:')
        ..addAll(done.map((d) => '- $d'));
    }
    if (widget.entry.turns.isNotEmpty) {
      lines
        ..add('')
        ..add('${l10n.callCardTranscriptTitle}:');
      for (final t in widget.entry.turns) {
        lines.add(
          '${t.role == 'user' ? l10n.callCardYou : widget.botName}: ${t.text}',
        );
      }
    }
    return lines.join('\n');
  }

  Future<void> _copy() async {
    Analytics.log('call_card_action', {'action': 'copied'});
    await Clipboard.setData(ClipboardData(text: _asText(context)));
    if (mounted) {
      showToast(context, context.l10n.callCardCopied, kind: ToastKind.success);
    }
  }

  Future<void> _delete() async {
    final id = widget.entry.liveCallId;
    if (id == null) return;
    final l10n = context.l10n;
    final ok = await showConfirm(
      context: context,
      title: l10n.callCardDeleteTitle,
      message: l10n.callCardDeleteBody,
      confirmLabel: l10n.callCardDelete,
      destructive: true,
    );
    if (!ok || !mounted) return;
    Analytics.log('call_card_action', {'action': 'deleted'});
    try {
      await widget.onDelete(id);
      if (mounted) {
        showToast(context, l10n.callCardDeleted, kind: ToastKind.success);
      }
    } catch (_) {
      if (mounted) {
        showToast(context, l10n.callCardDeleteFailed, kind: ToastKind.error);
      }
    }
  }

  Future<void> _step(MessageCallStep s, {bool dismiss = false}) async {
    final id = widget.entry.liveCallId;
    if (id == null || _busySteps.contains(s.id)) return;
    if (!dismiss) unawaited(HapticsHelper.light());
    Analytics.log('call_card_action', {
      'action': dismiss ? 'step_dismissed' : 'step_started',
    });
    setState(() => _busySteps.add(s.id));
    try {
      await widget.onStep(id, s.id, dismiss: dismiss);
    } catch (_) {
      if (mounted) {
        showToast(
          context,
          context.l10n.callCardStepFailed,
          kind: ToastKind.error,
        );
      }
    } finally {
      if (mounted) setState(() => _busySteps.remove(s.id));
    }
  }

  void _callBack() {
    Analytics.log('call_card_action', {'action': 'call_back'});
    widget.onCallBack();
  }

  void _openTranscript() {
    if (!_transcriptOpen) {
      Analytics.log('call_card_action', {'action': 'transcript_opened'});
    }
    final turns = widget.entry.turns;
    final total = math.max(turns.length, _call?.turns ?? 0);
    // Long, or not all loaded (an earlier page): the sheet, which reads the rest.
    if (total > callTranscriptInlineMax || turns.length < (_call?.turns ?? 0)) {
      unawaited(
        showAdaptiveSheet<void>(
          context: context,
          heightFactor: 0.9,
          contentPadsBottom: true,
          builder: (_) => CallTranscriptSheet(
            turns: turns,
            total: total,
            botName: widget.botName,
            load: _loadAllTurns,
          ),
        ),
      );
      return;
    }
    setState(() => _transcriptOpen = !_transcriptOpen);
  }

  /// Every turn of this call, read around its card (for a call longer than one page).
  Future<List<CallTurnView>> _loadAllTurns() async {
    final conv = widget.conversationId;
    final id = widget.entry.liveCallId;
    final total = _call?.turns ?? widget.entry.turns.length;
    if (conv == null || id == null || widget.entry.turns.length >= total) {
      return widget.entry.turns;
    }
    final messages = await ref
        .read(backendProvider)
        .messages(
          conv,
          around: widget.entry.messageId,
          limit: math.min(500, total * 2 + 40),
        );
    return [
      for (final m in messages)
        if (m.callId == id && m.call == null)
          CallTurnView(
            messageId: m.id,
            role: m.role,
            text: m.text,
            at: m.createdAt.toLocal(),
          ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final active = ref.watch(activeCallProvider);
    return ListenableBuilder(
      listenable: active,
      builder: (context, _) => _card(context, _liveHere(active)),
    );
  }

  Widget _card(BuildContext context, CallController? liveHere) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    final c = _call;
    final live = liveHere != null || _liveElsewhere;
    final turns = widget.entry.turns;
    final turnCount = math.max(turns.length, c?.turns ?? 0);
    final summary = c?.summaryStatus == 'ready' ? c?.summary : null;
    final steps = [
      for (final s in c?.steps ?? const <MessageCallStep>[])
        if (s.state != 'dismissed') s,
    ];
    final doneRows = <Widget>[
      for (final t in c?.tasks ?? const <MessageCallTask>[])
        _TaskRow(task: t, onOpen: () => widget.onOpenRun(t.runId)),
      for (final a in c?.actions ?? const <MessageCallAction>[])
        _ActionRow(action: a, onOpen: _actionTap(a)),
    ];
    final shownDone = _allDone || doneRows.length <= 4
        ? doneRows
        : doneRows.take(3).toList();
    final missed = c?.missed ?? false;
    final callBackFirst = missed || c?.ended == 'dropped';
    final title = live
        ? (liveHere != null
              ? l10n.callCardLive(widget.botName)
              : l10n.callCardLiveElsewhere)
        : _title(context);

    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Semantics(
          container: true,
          label: l10n.callCardSemantics(title, summary ?? c?.reason ?? ''),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: live
                    ? scheme.primary.withValues(alpha: 0.5)
                    : scheme.outlineVariant,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
              child: AnimatedSize(
                duration: AppMotion.of(
                  context,
                  const Duration(milliseconds: 250),
                ),
                curve: AppMotion.curve,
                alignment: Alignment.topCenter,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _Header(
                      icon: missed
                          ? LucideIcons.phoneMissed
                          : c?.ended == 'dropped'
                          ? LucideIcons.phoneOff
                          : LucideIcons.phone,
                      live: live,
                      tint: missed ? scheme.error : scheme.primary,
                      title: title,
                      subtitle: liveHere != null ? null : _subtitle(context),
                      timer: liveHere,
                      menu: live ? null : _menu(context),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // What it was about.
                          if (c?.reason case final r? when r.isNotEmpty) ...[
                            const SizedBox(height: AppSpace.xs),
                            Text(r, style: context.textTheme.bodyMedium),
                          ],
                          if (_waitingForSummary) ...[
                            const SizedBox(height: AppSpace.sm),
                            _SummaryWaiting(
                              key: const Key('callCardSummaryWaiting'),
                              label: l10n.callCardWritingSummary,
                            ),
                          ] else if (summary != null && summary.isNotEmpty) ...[
                            const SizedBox(height: AppSpace.xs),
                            _Summary(
                              text: summary,
                              open: _summaryOpen,
                              byline: l10n.callCardSummaryBy(widget.botName),
                              onTap: () =>
                                  setState(() => _summaryOpen = !_summaryOpen),
                            ),
                          ],
                          // While it goes on: the last thing said.
                          if (live && turns.isNotEmpty) ...[
                            const SizedBox(height: AppSpace.xs),
                            Text(
                              '“${turns.last.text}”',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: context.textTheme.bodyMedium?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                          if (steps.isNotEmpty) ...[
                            const SizedBox(height: AppSpace.sm),
                            _SectionLabel(l10n.callCardNextSteps),
                            for (final s in steps)
                              _StepRow(
                                key: Key('callStep-${s.id}'),
                                step: s,
                                busy: _busySteps.contains(s.id),
                                onStart: () => _step(s),
                                onDismiss: () => _step(s, dismiss: true),
                                onOpenRun: s.runId == null
                                    ? null
                                    : () => widget.onOpenRun(s.runId!),
                              ),
                          ],
                          if (doneRows.isNotEmpty) ...[
                            const SizedBox(height: AppSpace.sm),
                            _SectionLabel(
                              c != null &&
                                      c.tasks.isNotEmpty &&
                                      c.actions.isEmpty
                                  ? l10n.callRecapStarted
                                  : l10n.callCardDoneOnCall,
                            ),
                            ...shownDone,
                            if (shownDone.length < doneRows.length)
                              _MoreRow(
                                label: l10n.callCardMore(
                                  doneRows.length - shownDone.length,
                                ),
                                onTap: () => setState(() => _allDone = true),
                              ),
                          ],
                          if (turnCount > 0 && turns.isNotEmpty) ...[
                            const SizedBox(height: AppSpace.xxs),
                            _TranscriptToggle(
                              label: l10n.callCardTranscript(turnCount),
                              open: _transcriptOpen,
                              onTap: _openTranscript,
                            ),
                            if (_transcriptOpen)
                              _TranscriptInline(
                                turns: turns,
                                botName: widget.botName,
                              ),
                          ],
                          if (!live || liveHere != null) ...[
                            const SizedBox(height: AppSpace.sm),
                            Wrap(
                              spacing: AppSpace.xs,
                              runSpacing: AppSpace.xs,
                              children: [
                                if (liveHere != null)
                                  FilledButton.icon(
                                    key: const Key('callCardReturn'),
                                    onPressed: () => widget.onOpenPath(
                                      callScreenPath(liveHere),
                                    ),
                                    icon: const Icon(
                                      LucideIcons.phone,
                                      size: 16,
                                    ),
                                    label: Text(l10n.callCardReturn),
                                  )
                                else if (callBackFirst)
                                  FilledButton.icon(
                                    key: const Key('callCardCallBack'),
                                    onPressed: _callBack,
                                    icon: const Icon(
                                      LucideIcons.phoneOutgoing,
                                      size: 16,
                                    ),
                                    label: Text(l10n.callCardCallBack),
                                  )
                                else
                                  OutlinedButton.icon(
                                    key: const Key('callCardCallBack'),
                                    onPressed: _callBack,
                                    icon: const Icon(
                                      LucideIcons.phoneOutgoing,
                                      size: 16,
                                    ),
                                    label: Text(l10n.callCardCallBack),
                                  ),
                                if (liveHere == null &&
                                    (summary != null || turns.isNotEmpty))
                                  TextButton.icon(
                                    key: const Key('callCardCopy'),
                                    onPressed: _copy,
                                    icon: const Icon(
                                      LucideIcons.copy,
                                      size: 16,
                                    ),
                                    label: Text(l10n.callCardCopy),
                                  ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  VoidCallback? _actionTap(MessageCallAction a) => switch (a.targetKind) {
    'memory' => () => widget.onOpenPath('/bots/${widget.botId}/memory'),
    'routine' => () => widget.onOpenPath('/bots/${widget.botId}/routines'),
    'task' => () => widget.onOpenPath('/tasks'),
    _ => () => widget.onOpenRun(a.runId),
  };

  Widget _menu(BuildContext context) {
    final l10n = context.l10n;
    return MenuAnchor(
      menuChildren: [
        MenuItemButton(
          leadingIcon: const Icon(LucideIcons.copy, size: 18),
          onPressed: _copy,
          child: Text(l10n.callCardCopy),
        ),
        MenuItemButton(
          leadingIcon: const Icon(LucideIcons.share2, size: 18),
          onPressed: () {
            Analytics.log('call_card_action', {'action': 'shared'});
            final box = context.findRenderObject() as RenderBox?;
            unawaited(
              shareText(
                _asText(context),
                origin: box == null
                    ? null
                    : box.localToGlobal(Offset.zero) & box.size,
              ),
            );
          },
          child: Text(l10n.callCardShare),
        ),
        if (widget.entry.liveCallId != null)
          MenuItemButton(
            key: const Key('callCardDelete'),
            leadingIcon: Icon(
              LucideIcons.trash2,
              size: 18,
              color: context.colorScheme.error,
            ),
            onPressed: _delete,
            child: Text(
              l10n.callCardDelete,
              style: TextStyle(color: context.colorScheme.error),
            ),
          ),
      ],
      builder: (context, menu, _) => IconButton(
        key: const Key('callCardMenu'),
        tooltip: l10n.callCardMoreActions,
        visualDensity: VisualDensity.compact,
        icon: const Icon(LucideIcons.ellipsis, size: 18),
        onPressed: () => menu.isOpen ? menu.close() : menu.open(),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.icon,
    required this.live,
    required this.tint,
    required this.title,
    required this.subtitle,
    required this.timer,
    required this.menu,
  });
  final IconData icon;
  final bool live;
  final Color tint;
  final String title;
  final String? subtitle;
  final CallController? timer;
  final Widget? menu;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final sub = subtitle;
    return Row(
      children: [
        _Badge(icon: icon, tint: tint, live: live),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: context.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontFeatures: AppText.tabular,
                ),
              ),
              if (timer case final t?)
                CallTimerText(
                  call: t,
                  style: context.textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                )
              else if (sub != null && sub.isNotEmpty)
                Text(
                  sub,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontFeatures: AppText.tabular,
                  ),
                ),
            ],
          ),
        ),
        ?menu,
        if (menu == null) const SizedBox(width: 8),
      ],
    );
  }
}

/// The phone in a soft circle; it breathes while the call is live (still under reduce-motion).
class _Badge extends StatefulWidget {
  const _Badge({required this.icon, required this.tint, required this.live});
  final IconData icon;
  final Color tint;
  final bool live;

  @override
  State<_Badge> createState() => _BadgeState();
}

class _BadgeState extends State<_Badge> with SingleTickerProviderStateMixin {
  late final _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(_Badge old) {
    super.didUpdateWidget(old);
    _sync();
  }

  void _sync() {
    final animate = widget.live && !MediaQuery.disableAnimationsOf(context);
    if (animate && !_pulse.isAnimating) {
      unawaited(_pulse.repeat(reverse: true));
    } else if (!animate && _pulse.isAnimating) {
      _pulse
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) => DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.tint.withValues(alpha: 0.12 + 0.1 * _pulse.value),
        ),
        child: child,
      ),
      child: SizedBox.square(
        dimension: 32,
        child: Icon(widget.icon, size: 16, color: widget.tint),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 2),
    child: Text(
      text.toUpperCase(),
      style: context.textTheme.labelSmall?.copyWith(
        color: context.colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.6,
      ),
    ),
  );
}

/// Two shimmering lines while the summary is written; still text under reduce-motion.
class _SummaryWaiting extends StatelessWidget {
  const _SummaryWaiting({super.key, required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return Text(
        label,
        style: context.textTheme.bodyMedium?.copyWith(
          color: context.colorScheme.onSurfaceVariant,
        ),
      );
    }
    return Semantics(
      label: label,
      child: const SkeletonScope(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonBone(height: 11),
            SizedBox(height: 7),
            FractionallySizedBox(
              widthFactor: 0.6,
              child: SkeletonBone(height: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({
    required this.text,
    required this.open,
    required this.byline,
    required this.onTap,
  });
  final String text;
  final bool open;
  final String byline;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey(text),
      tween: Tween(begin: 0, end: 1),
      duration: AppMotion.of(context, const Duration(milliseconds: 200)),
      builder: (context, v, child) => Opacity(opacity: v, child: child),
      child: InkWell(
        key: const Key('callCardSummary'),
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                text,
                maxLines: open ? null : 3,
                overflow: open ? null : TextOverflow.ellipsis,
                style: context.textTheme.bodyMedium?.copyWith(height: 1.4),
              ),
              if (open)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    byline,
                    style: context.textTheme.labelSmall?.copyWith(
                      color: context.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    super.key,
    required this.step,
    required this.busy,
    required this.onStart,
    required this.onDismiss,
    required this.onOpenRun,
  });
  final MessageCallStep step;
  final bool busy;
  final VoidCallback onStart;
  final VoidCallback onDismiss;
  final VoidCallback? onOpenRun;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    final started = step.state == 'started';
    final big = MediaQuery.textScalerOf(context).scale(1) > 1.3;
    final label = Text(
      step.label,
      style: context.textTheme.bodyMedium?.copyWith(
        color: started ? scheme.onSurfaceVariant : null,
      ),
    );
    final Widget trailing;
    if (started) {
      trailing = TextButton(
        onPressed: onOpenRun,
        style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
        child: Text('${l10n.callCardStepStarted} ›'),
      );
    } else if (step.doable) {
      trailing = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FilledButton.tonal(
            key: Key('callStepDo-${step.id}'),
            onPressed: busy ? null : onStart,
            style: FilledButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 14),
            ),
            child: busy
                ? const SizedBox.square(
                    dimension: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.callCardDoIt),
          ),
          IconButton(
            key: Key('callStepDismiss-${step.id}'),
            tooltip: l10n.callCardDismissStep,
            visualDensity: VisualDensity.compact,
            onPressed: busy ? null : onDismiss,
            icon: Icon(LucideIcons.x, size: 16, color: scheme.onSurfaceVariant),
          ),
        ],
      );
    } else {
      trailing = IconButton(
        key: Key('callStepDismiss-${step.id}'),
        tooltip: l10n.callCardDismissStep,
        visualDensity: VisualDensity.compact,
        onPressed: busy ? null : onDismiss,
        icon: Icon(LucideIcons.x, size: 16, color: scheme.onSurfaceVariant),
      );
    }
    final icon = Icon(
      started ? LucideIcons.loader : LucideIcons.circleDashed,
      size: 16,
      color: started ? scheme.primary : scheme.onSurfaceVariant,
    );
    if (big) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                icon,
                const SizedBox(width: 8),
                Expanded(child: label),
              ],
            ),
            Align(alignment: AlignmentDirectional.centerEnd, child: trailing),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          icon,
          const SizedBox(width: 8),
          Expanded(child: label),
          trailing,
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({required this.action, required this.onOpen});
  final MessageCallAction action;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onOpen,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(
              action.ok ? LucideIcons.check : LucideIcons.x,
              size: 16,
              color: action.ok ? context.appColors.positive : scheme.error,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                action.label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.bodyMedium,
              ),
            ),
            if (onOpen != null)
              Icon(
                LucideIcons.chevronRight,
                size: 16,
                color: scheme.onSurfaceVariant,
              ),
          ],
        ),
      ),
    );
  }
}

class _TaskRow extends StatelessWidget {
  const _TaskRow({required this.task, required this.onOpen});
  final MessageCallTask task;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    final (icon, tint, state) = switch (task.status) {
      'completed' => (
        LucideIcons.check,
        context.appColors.positive,
        l10n.callRecapTaskDone,
      ),
      'failed' => (LucideIcons.x, scheme.error, l10n.callRecapTaskFailed),
      'cancelled' => (
        LucideIcons.circleStop,
        scheme.onSurfaceVariant,
        l10n.callRecapTaskStopped,
      ),
      _ => (LucideIcons.loader, scheme.primary, l10n.callRecapTaskRunning),
    };
    return InkWell(
      key: Key('callRecapRun-${task.runId}'),
      borderRadius: BorderRadius.circular(10),
      onTap: onOpen,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(icon, size: 16, color: tint),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.task,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.bodyMedium,
                  ),
                  Text(
                    '$state · ${l10n.callRecapOpenRun}',
                    style: context.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              LucideIcons.chevronRight,
              size: 16,
              color: scheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

class _MoreRow extends StatelessWidget {
  const _MoreRow({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: onTap,
    style: TextButton.styleFrom(
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
    ),
    child: Text(label),
  );
}

class _TranscriptToggle extends StatelessWidget {
  const _TranscriptToggle({
    required this.label,
    required this.open,
    required this.onTap,
  });
  final String label;
  final bool open;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    return InkWell(
      key: const Key('callCardTranscript'),
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            AnimatedRotation(
              turns: open ? 0.25 : 0,
              duration: AppMotion.of(context, AppMotion.fast),
              child: Icon(
                LucideIcons.chevronRight,
                size: 16,
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: context.textTheme.labelLarge?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The call's turns, compact: who spoke and what they said, a time in the margin each minute.
class _TranscriptInline extends StatelessWidget {
  const _TranscriptInline({required this.turns, required this.botName});
  final List<CallTurnView> turns;
  final String botName;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 22, bottom: 4),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (i, t) in turns.indexed)
          CallTurnLine(
            turn: t,
            botName: botName,
            showTime: _minuteMark(turns, i),
          ),
      ],
    ),
  );
}

/// Whether turn [i] starts a new minute of the call (its time is shown).
bool _minuteMark(List<CallTurnView> turns, int i) =>
    i == 0 ||
    turns[i].at.difference(turns[i - 1].at).inSeconds >= 60 ||
    turns[i].at.minute != turns[i - 1].at.minute;

/// One spoken turn in a transcript.
class CallTurnLine extends StatelessWidget {
  const CallTurnLine({
    super.key,
    required this.turn,
    required this.botName,
    this.showTime = false,
    this.highlight,
  });
  final CallTurnView turn;
  final String botName;
  final bool showTime;

  /// Words to mark (a search in the sheet).
  final String? highlight;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final you = turn.role == 'user';
    final base = context.textTheme.bodySmall?.copyWith(
      height: 1.4,
      color: scheme.onSurface,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: SelectionArea(
        child: Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: '${you ? context.l10n.callCardYou : botName}  ',
                style: base?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: you ? scheme.onSurface : scheme.primary,
                ),
              ),
              ..._marked(turn.text, highlight, base, scheme),
              if (showTime)
                TextSpan(
                  text:
                      '  ${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(turn.at))}',
                  style: base?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontSize: (base.fontSize ?? 12) - 1,
                    fontFeatures: AppText.tabular,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  static List<TextSpan> _marked(
    String text,
    String? q,
    TextStyle? base,
    ColorScheme scheme,
  ) {
    if (q == null || q.trim().isEmpty) {
      return [TextSpan(text: text, style: base)];
    }
    final lower = text.toLowerCase();
    final needle = q.trim().toLowerCase();
    final out = <TextSpan>[];
    var from = 0;
    for (
      var at = lower.indexOf(needle);
      at >= 0;
      at = lower.indexOf(needle, from)
    ) {
      if (at > from) {
        out.add(TextSpan(text: text.substring(from, at), style: base));
      }
      out.add(
        TextSpan(
          text: text.substring(at, at + needle.length),
          style: base?.copyWith(
            backgroundColor: scheme.primary.withValues(alpha: 0.18),
            fontWeight: FontWeight.w600,
          ),
        ),
      );
      from = at + needle.length;
    }
    if (from < text.length) {
      out.add(TextSpan(text: text.substring(from), style: base));
    }
    return out;
  }
}

/// A long call's transcript in a sheet: search, copy, and the turns not loaded with the chat.
class CallTranscriptSheet extends StatefulWidget {
  const CallTranscriptSheet({
    super.key,
    required this.turns,
    required this.total,
    required this.botName,
    required this.load,
  });
  final List<CallTurnView> turns;
  final int total;
  final String botName;
  final Future<List<CallTurnView>> Function() load;

  @override
  State<CallTranscriptSheet> createState() => _CallTranscriptSheetState();
}

class _CallTranscriptSheetState extends State<CallTranscriptSheet> {
  late List<CallTurnView> _turns = widget.turns;
  var _query = '';

  @override
  void initState() {
    super.initState();
    if (_turns.length < widget.total) {
      unawaited(
        widget
            .load()
            .then((t) {
              if (mounted && t.length > _turns.length) {
                setState(() => _turns = t);
              }
            })
            .catchError((Object _) {}),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final q = _query.trim().toLowerCase();
    final shown = q.isEmpty
        ? _turns
        : [
            for (final t in _turns)
              if (t.text.toLowerCase().contains(q)) t,
          ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 12, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l10n.callCardTranscriptTitle,
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                tooltip: l10n.callCardCopy,
                icon: const Icon(LucideIcons.copy, size: 18),
                onPressed: () async {
                  final text = [
                    for (final t in _turns)
                      '${t.role == 'user' ? l10n.callCardYou : widget.botName}: ${t.text}',
                  ].join('\n');
                  await Clipboard.setData(ClipboardData(text: text));
                  if (context.mounted) {
                    showToast(
                      context,
                      l10n.callCardCopied,
                      kind: ToastKind.success,
                    );
                  }
                },
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            key: const Key('callTranscriptSearch'),
            onChanged: (v) => setState(() => _query = v),
            decoration: InputDecoration(
              isDense: true,
              prefixIcon: const Icon(LucideIcons.search, size: 18),
              hintText: l10n.callCardSearchTranscript,
            ),
          ),
        ),
        const SizedBox(height: AppSpace.xs),
        Expanded(
          child: shown.isEmpty
              ? Center(
                  child: Text(
                    l10n.callCardNoMatches,
                    style: context.textTheme.bodyMedium,
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    4,
                    20,
                    16 + MediaQuery.paddingOf(context).bottom,
                  ),
                  itemCount: shown.length,
                  itemBuilder: (context, i) => CallTurnLine(
                    turn: shown[i],
                    botName: widget.botName,
                    showTime: q.isEmpty && _minuteMark(shown, i),
                    highlight: q.isEmpty ? null : _query,
                  ),
                ),
        ),
      ],
    );
  }
}
