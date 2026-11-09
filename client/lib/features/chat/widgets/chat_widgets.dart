import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/widgets.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../theme/app_colors.dart';
import '../../../core/backend.dart';
import '../../../theme/app_tokens.dart';
import '../../files/file_preview.dart';
import '../../../ui/app_card.dart';
import '../../../ui/bot_avatar.dart';
import '../../../ui/motion.dart';
import '../chat_controller.dart';
import 'chat_markdown.dart';

// ---------------------------------------------------------------------------------------------
// Messages

/// What you wrote: a bubble on the right in the accent tint, the tail corner tucked in, with any
/// attached files above it.
class UserBubble extends StatelessWidget {
  const UserBubble({super.key, required this.text, this.attachments = const []});
  final String text;
  final List<AttachmentRef> attachments;

  @override
  Widget build(BuildContext context) {
    if (attachments.isEmpty) return _bubble(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
      Wrap(alignment: WrapAlignment.end, spacing: AppSpace.xs, runSpacing: AppSpace.xs, children: [
        for (final a in attachments) AttachmentTile(attachment: a),
      ]),
      if (text.isNotEmpty) ...[const SizedBox(height: 6), _bubble(context)],
    ]);
  }

  Widget _bubble(BuildContext context) {
    final scheme = context.colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) => Align(
        alignment: AlignmentDirectional.centerEnd,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: (constraints.maxWidth * 0.85).clamp(0, 560)),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: context.isDark ? 0.24 : 0.12),
              borderRadius: const BorderRadiusDirectional.only(
                topStart: Radius.circular(20),
                topEnd: Radius.circular(20),
                bottomStart: Radius.circular(20),
                bottomEnd: Radius.circular(6),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: 11),
              child: SelectableText(text, style: context.textTheme.bodyLarge?.copyWith(height: 1.4)),
            ),
          ),
        ),
      ),
    );
  }
}

/// The bot's name and mark, once at the start of each of its turns.
class BotTurnHeader extends StatelessWidget {
  const BotTurnHeader({super.key, required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.xs),
      child: Row(children: [
        BotAvatar(name: name, size: 24),
        const SizedBox(width: AppSpace.xs),
        Text(name, style: context.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
      ]),
    );
  }
}

/// The bot's reply: full width so code and tables get the room, with copy and read aloud below.
class AssistantMessage extends StatelessWidget {
  const AssistantMessage({super.key, required this.entry, this.onSpeak, this.status});
  final MessageEntry entry;
  final VoidCallback? onSpeak;

  /// What the bot is doing while the reply is still empty.
  final String? status;

  @override
  Widget build(BuildContext context) {
    if (entry.text.isEmpty && entry.streaming) return WorkingIndicator(status: status ?? context.l10n.thinking);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      ChatMarkdown(data: entry.text),
      if (entry.streaming)
        Padding(padding: const EdgeInsets.only(top: AppSpace.xs), child: _TypingDots(color: context.colorScheme.primary))
      else
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Row(children: [
            _CopyButton(text: entry.text),
            if (onSpeak != null)
              _FooterIcon(
                key: Key('speak-${entry.id}'),
                icon: Icons.volume_up_outlined,
                tooltip: context.l10n.readAloud,
                onPressed: onSpeak!,
              ),
          ]),
        ),
    ]);
  }
}

class _FooterIcon extends StatelessWidget {
  const _FooterIcon({super.key, required this.icon, required this.tooltip, required this.onPressed});
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        visualDensity: VisualDensity.compact,
        icon: Icon(icon, size: 18, color: context.colorScheme.onSurfaceVariant),
      );
}

class _CopyButton extends StatefulWidget {
  const _CopyButton({required this.text});
  final String text;

  @override
  State<_CopyButton> createState() => _CopyButtonState();
}

class _CopyButtonState extends State<_CopyButton> {
  var _copied = false;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.text));
    HapticFeedback.lightImpact();
    if (!mounted) return;
    setState(() => _copied = true);
    await Future<void>.delayed(const Duration(milliseconds: 1600));
    if (mounted) setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: _copied ? context.l10n.copied : MaterialLocalizations.of(context).copyButtonLabel,
      onPressed: _copy,
      visualDensity: VisualDensity.compact,
      icon: AnimatedSwitcher(
        duration: AppMotion.of(context, AppMotion.fast),
        transitionBuilder: (child, a) => ScaleTransition(scale: a, child: child),
        child: Icon(
          _copied ? Icons.check_rounded : Icons.content_copy_rounded,
          key: ValueKey(_copied),
          size: 17,
          color: _copied ? context.appColors.positive : context.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// Three dots that pulse in turn while a reply streams (one controller, no timers).
class _TypingDots extends StatefulWidget {
  const _TypingDots({required this.color});
  final Color color;

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));

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
      builder: (context, _) => Row(mainAxisSize: MainAxisSize.min, children: [
        for (var i = 0; i < 3; i++)
          Builder(builder: (context) {
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
                  decoration: BoxDecoration(color: widget.color.withValues(alpha: 0.25 + 0.75 * v), shape: BoxShape.circle),
                ),
              ),
            );
          }),
      ]),
    );
  }
}

/// What the bot is doing right now, over a shimmering placeholder for the reply.
class WorkingIndicator extends StatelessWidget {
  const WorkingIndicator({super.key, required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final still = MediaQuery.disableAnimationsOf(context);
    Widget sparkle = Icon(Icons.auto_awesome_rounded, size: 18, color: scheme.primary);
    Widget text = Text(
      status,
      key: ValueKey(status),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: context.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant, fontWeight: FontWeight.w500),
    );
    Widget placeholder = _Placeholder(color: scheme.onSurface);
    if (!still) {
      sparkle = Pulse(from: 0.8, to: 1.1, fadeFrom: 0.55, duration: const Duration(milliseconds: 700), child: sparkle);
      text = Shimmer(key: ValueKey(status), color: scheme.primary.withValues(alpha: 0.7), child: text);
      placeholder = Shimmer(color: scheme.surface.withValues(alpha: 0.6), child: placeholder);
    }
    return Semantics(
      liveRegion: true,
      label: status,
      child: ExcludeSemantics(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            sparkle,
            const SizedBox(width: AppSpace.xs),
            Flexible(child: AnimatedSwitcher(duration: AppMotion.of(context, AppMotion.fast), child: text)),
          ]),
          const SizedBox(height: AppSpace.sm),
          placeholder,
        ]),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    Widget bar(double f) => FractionallySizedBox(
          widthFactor: f,
          child: Container(
            height: 12,
            margin: const EdgeInsets.only(bottom: AppSpace.xs),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(6)),
          ),
        );
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [bar(0.92), bar(0.74), bar(0.48)]);
  }
}

/// An attached file: a thumbnail for images, a chip for the rest. Tap to open it.
class AttachmentTile extends ConsumerWidget {
  const AttachmentTile({super.key, required this.attachment});
  final AttachmentRef attachment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scope = FileLinkScope.maybeOf(context);
    final path = computerPathFromLink(attachment.path) ?? attachment.path;
    final scheme = context.colorScheme;
    void open() => scope?.open(path);
    if (attachment.isImage && scope?.computerId != null) {
      final bytes = ref.watch(computerFileProvider((scope!.computerId!, path))).value;
      return Tooltip(
        message: attachment.name,
        child: InkWell(
          key: Key('attachment-${attachment.path}'),
          onTap: open,
          borderRadius: BorderRadius.circular(AppRadius.tile),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.tile),
            child: Container(
              width: 168,
              height: 126,
              color: scheme.surfaceContainerHigh,
              child: bytes == null
                  ? Center(child: Icon(Icons.image_outlined, color: scheme.onSurfaceVariant))
                  : Image.memory(bytes, fit: BoxFit.cover, gaplessPlayback: true, errorBuilder: (_, _, _) => Icon(Icons.broken_image_outlined, color: scheme.onSurfaceVariant)),
            ),
          ),
        ),
      );
    }
    return Material(
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.rowAll, side: BorderSide(color: context.appColors.hairline)),
      child: InkWell(
        key: Key('attachment-${attachment.path}'),
        onTap: open,
        customBorder: RoundedRectangleBorder(borderRadius: AppRadius.rowAll),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 14, 8),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(fileIconFor(attachment.name), size: 20, color: scheme.primary),
            const SizedBox(width: AppSpace.xs),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 220),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                Text(attachment.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600)),
                if (attachment.size > 0) Text(formatBytes(attachment.size), style: context.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant)),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------------------------
// Tool steps

/// A tool's action in plain words ("Ran a command"), with its icon.
(String, IconData) toolLabel(AppLocalizations l10n, String tool) {
  if (tool.startsWith('shell')) return (l10n.toolShell, Icons.terminal_rounded);
  if (tool == 'files.read' || tool == 'files.list') return (l10n.toolFileRead, Icons.description_outlined);
  if (tool == 'files.write' || tool == 'files.edit') return (l10n.toolFileWrite, Icons.edit_note_rounded);
  if (tool.startsWith('files')) return (l10n.toolFiles, Icons.folder_outlined);
  if (tool.startsWith('browser')) return (l10n.toolBrowser, Icons.language_rounded);
  if (tool.startsWith('web') || tool.contains('search')) return (l10n.toolSearch, Icons.travel_explore_rounded);
  if (tool.startsWith('memory')) return (l10n.toolMemory, Icons.psychology_outlined);
  if (tool.startsWith('skills')) return (l10n.toolSkill, Icons.menu_book_outlined);
  if (tool.startsWith('checkpoint')) return (l10n.toolCheckpoint, Icons.restore_rounded);
  if (tool == 'computer.request_takeover') return (l10n.toolTakeover, Icons.front_hand_outlined);
  if (tool.startsWith('desktop') || tool.startsWith('computer')) return (l10n.toolDesktop, Icons.mouse_outlined);
  if (tool.contains('delegate') || tool.contains('subagent')) return (l10n.toolDelegate, Icons.group_outlined);
  if (tool == 'routines.create') return (l10n.toolRoutineCreate, Icons.alarm_add_rounded);
  if (tool == 'routines.delete') return (l10n.toolRoutineDelete, Icons.alarm_off_rounded);
  if (tool.startsWith('routines')) return (l10n.toolRoutines, Icons.schedule_rounded);
  if (tool.startsWith('tasks')) return (l10n.toolTasks, Icons.checklist_rounded);
  if (tool.startsWith('notify')) return (l10n.toolNotify, Icons.notifications_active_outlined);
  if (tool.startsWith('http')) return (l10n.toolHttp, Icons.public_rounded);
  if (tool.startsWith('media')) return (l10n.toolMedia, Icons.auto_awesome_outlined);
  return (l10n.toolOther(tool), Icons.build_outlined);
}

String toolSummary(ToolEntry t) {
  final a = t.args;
  final key = ['command', 'cmd', 'url', 'path', 'query', 'ref', 'label', 'name', 'content'].firstWhere((k) => a[k] != null, orElse: () => '');
  if (key.isEmpty) return '';
  final v = '${a[key]}'.replaceAll('\n', ' ');
  return v.length > 90 ? '${v.substring(0, 87)}…' : v;
}

String formatDuration(int ms) => ms < 1000 ? '$ms ms' : '${(ms / 1000).toStringAsFixed(ms < 10000 ? 1 : 0)} s';

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
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            if (folded)
              InkWell(
                onTap: () => setState(() => _showAll = true),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 12, 10),
                  child: Row(children: [
                    Icon(Icons.unfold_more_rounded, size: 18, color: context.colorScheme.onSurfaceVariant),
                    const SizedBox(width: AppSpace.xs),
                    Expanded(
                      child: Text(
                        l10n.showMoreSteps(steps.length - visible.length),
                        style: context.textTheme.labelLarge?.copyWith(color: context.colorScheme.onSurfaceVariant),
                      ),
                    ),
                    Text(
                      '${l10n.toolSteps(steps.length)} · ${formatDuration(totalMs)}',
                      style: context.textTheme.labelMedium?.copyWith(color: context.colorScheme.onSurfaceVariant, fontFeatures: AppText.tabular),
                    ),
                  ]),
                ),
              ),
            for (var i = 0; i < visible.length; i++) ...[
              if (i > 0 || folded) Divider(indent: 50, color: context.appColors.hairline),
              _ToolStepRow(
                key: ValueKey(visible[i].callId),
                entry: visible[i],
                open: _open.contains(visible[i].callId),
                onToggle: () => setState(() => _open.contains(visible[i].callId) ? _open.remove(visible[i].callId) : _open.add(visible[i].callId)),
              ),
            ],
          ]),
        ),
      ),
    );
  }
}

class _ToolStepRow extends StatelessWidget {
  const _ToolStepRow({super.key, required this.entry, required this.open, required this.onToggle});
  final ToolEntry entry;
  final bool open;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    final colors = context.appColors;
    final (label, icon) = toolLabel(l10n, entry.tool);
    final failed = entry.status == ToolStatus.failed;
    final tint = failed ? colors.negative : scheme.primary;
    final summary = toolSummary(entry);
    final Widget status = switch (entry.status) {
      ToolStatus.running => SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, strokeCap: StrokeCap.round, color: scheme.primary)),
      ToolStatus.done => Text(
          formatDuration(entry.durationMs ?? 0),
          style: context.textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant, fontFeatures: AppText.tabular),
        ),
      ToolStatus.failed => Text(l10n.toolFailedLabel, style: context.textTheme.labelMedium?.copyWith(color: colors.negative, fontWeight: FontWeight.w600)),
    };
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      InkWell(
        onTap: onToggle,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Row(children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(color: tint.withValues(alpha: context.isDark ? 0.2 : 0.1), borderRadius: BorderRadius.circular(8)),
              alignment: Alignment.center,
              child: Icon(failed ? Icons.error_outline_rounded : icon, size: 15, color: tint),
            ),
            const SizedBox(width: AppSpace.sm),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                if (summary.isNotEmpty)
                  Text(
                    summary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.mono.copyWith(fontSize: 12, color: scheme.onSurfaceVariant, height: 1.35),
                  ),
              ]),
            ),
            const SizedBox(width: AppSpace.xs),
            status,
            const SizedBox(width: 2),
            AnimatedRotation(
              turns: open ? 0.5 : 0,
              duration: AppMotion.of(context, AppMotion.fast),
              child: Icon(Icons.expand_more_rounded, size: 18, color: scheme.onSurfaceVariant),
            ),
          ]),
        ),
      ),
      AnimatedSize(
        duration: AppMotion.of(context, const Duration(milliseconds: 220)),
        curve: AppMotion.curve,
        alignment: Alignment.topCenter,
        child: open ? _ToolDetails(entry: entry) : const SizedBox(width: double.infinity),
      ),
    ]);
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
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Expanded(child: Text(entry.tool, style: AppText.mono.copyWith(fontSize: 12, color: scheme.onSurfaceVariant, fontWeight: FontWeight.w600))),
          if (filePath != null && files != null && entry.status == ToolStatus.done)
            TextButton.icon(
              key: Key('openToolFile-${entry.callId}'),
              onPressed: () => files.open(filePath),
              icon: const Icon(Icons.open_in_new_rounded, size: 16),
              label: Text(l10n.openFileInChat),
            ),
        ]),
        const SizedBox(height: 6),
        CodePanel(text: const JsonEncoder.withIndent('  ').convert(entry.args)),
        if (entry.output.isNotEmpty) ...[
          const SizedBox(height: AppSpace.xs),
          Text(l10n.toolOutput, style: context.textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant)),
          const SizedBox(height: 4),
          CodePanel(text: entry.output, maxHeight: 240, reverse: true),
        ],
        if (entry.preview != null && entry.output.isEmpty) ...[
          const SizedBox(height: AppSpace.xs),
          SelectableText(entry.preview!, style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
        ],
        if (entry.error != null) ...[
          const SizedBox(height: AppSpace.xs),
          SelectableText(entry.error!, style: context.textTheme.bodySmall?.copyWith(color: context.appColors.negative)),
        ],
      ]),
    );
  }
}

/// The file a tool step made or read, as a files API path (null when it isn't about a file).
String? _toolFile(ToolEntry t) {
  final artifact = t.artifactPath;
  if (artifact != null && artifact.isNotEmpty) return computerPathFromLink(artifact);
  if (!t.tool.startsWith('files.') || t.tool == 'files.list' || t.tool == 'files.search' || t.tool == 'files.delete') return null;
  final p = t.args['path'];
  return p is String && p.isNotEmpty ? computerPathFromLink(p) : null;
}

/// Monospaced text on the code surface (arguments, output).
class CodePanel extends StatelessWidget {
  const CodePanel({super.key, required this.text, this.maxHeight = 200, this.reverse = false, this.maxLines});
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
        reverse: reverse,
        child: maxLines == null
            ? SelectableText(text, style: AppText.mono.copyWith(fontSize: 12.5))
            : Text(text, maxLines: maxLines, overflow: TextOverflow.ellipsis, style: AppText.mono.copyWith(fontSize: 12.5)),
      ),
    );
  }
}

// ---------------------------------------------------------------------------------------------
// Notices, approvals, takeovers

/// A short note in the thread (memory saved, checkpoint, computer state, run ended), centered.
class NoticeLine extends StatelessWidget {
  const NoticeLine({super.key, required this.entry, this.onRestore});
  final NoticeEntry entry;
  final void Function(String checkpointId)? onRestore;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    final colors = context.appColors;
    final muted = scheme.onSurfaceVariant;
    final (icon, text, color) = switch (entry.kind) {
      NoticeKind.memory => (Icons.psychology_outlined, l10n.remembered, muted),
      NoticeKind.skill => (Icons.menu_book_outlined, l10n.skillLoaded(entry.text), muted),
      NoticeKind.checkpoint => (Icons.restore_rounded, l10n.checkpointSaved(entry.text), muted),
      NoticeKind.computer => (Icons.desktop_windows_outlined, l10n.computerState(entry.text), muted),
      NoticeKind.failed => (Icons.error_outline_rounded, l10n.runFailed(entry.text), colors.negative),
      NoticeKind.cancelled => (Icons.stop_circle_outlined, l10n.runCancelled, muted),
      NoticeKind.userControl => (Icons.pan_tool_outlined, l10n.pausedUserInControl, colors.warning),
      NoticeKind.botControl => (Icons.smart_toy_outlined, l10n.botBackInControl, muted),
    };
    final failed = entry.kind == NoticeKind.failed;
    final restorable = entry.kind == NoticeKind.checkpoint && entry.refId != null && onRestore != null;
    return Center(
      child: Container(
        padding: EdgeInsets.fromLTRB(12, restorable ? 2 : 6, restorable ? 4 : 12, restorable ? 2 : 6),
        decoration: BoxDecoration(
          color: failed ? colors.negative.withValues(alpha: 0.08) : scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(failed ? AppRadius.row : AppRadius.pill),
          border: Border.all(color: failed ? colors.negative.withValues(alpha: 0.24) : colors.hairline),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Flexible(child: Text(text, style: context.textTheme.labelMedium?.copyWith(color: color, height: 1.3))),
          if (restorable) TextButton(onPressed: () => onRestore!(entry.refId!), child: Text(l10n.restore)),
        ]),
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

  Future<void> _decide(bool approve, {bool always = false}) async {
    HapticFeedback.mediumImpact();
    setState(() => _busy = true);
    final ok = await runGuarded(context, () async {
      await ref.read(backendProvider).decideApproval(widget.entry.approvalId, approve: approve, alwaysAllow: always);
      return true;
    });
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (ok == true) _localDecision = approve ? 'approved' : 'denied';
    });
    if (ok == true) ref.invalidate(approvalsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final e = widget.entry;
    final decision = e.decision ?? _localDecision;
    final high = e.risk == 'high';
    final accent = high ? colors.negative : colors.warning;
    final (action, _) = toolLabel(l10n, e.tool);
    return _ActionCard(
      key: const Key('chatApproval'),
      accent: accent,
      icon: high ? Icons.gpp_maybe_outlined : Icons.verified_user_outlined,
      title: l10n.needsApprovalFor(widget.botName, e.tool),
      badge: StatusLabel(text: high ? l10n.riskHigh : l10n.riskMedium, color: accent, pill: true),
      subtitle: action,
      body: CodePanel(text: const JsonEncoder.withIndent('  ').convert(e.args), maxLines: 8, maxHeight: 180),
      footer: decision != null
          ? _Outcome(
              text: switch (decision) { 'approved' => l10n.approved, 'denied' => l10n.denied, _ => l10n.expired },
              color: decision == 'approved' ? colors.positive : (decision == 'denied' ? colors.negative : context.colorScheme.onSurfaceVariant),
              icon: decision == 'approved' ? Icons.check_circle_rounded : (decision == 'denied' ? Icons.cancel_rounded : Icons.schedule_rounded),
            )
          : Wrap(alignment: WrapAlignment.end, spacing: AppSpace.xs, runSpacing: AppSpace.xs, children: [
              TextButton(onPressed: _busy ? null : () => _decide(true, always: true), child: Text(l10n.alwaysAllow)),
              OutlinedButton(onPressed: _busy ? null : () => _decide(false), child: Text(l10n.deny)),
              FilledButton(key: const Key('chatApprove'), onPressed: _busy ? null : () => _decide(true), child: Text(l10n.approve)),
            ]),
    );
  }
}

/// A bot asking a person to take over its screen (a sign-in, a captcha).
class TakeoverPrompt extends StatelessWidget {
  const TakeoverPrompt({super.key, required this.entry, required this.botName, required this.onOpen});
  final TakeoverEntry entry;
  final String botName;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    return _ActionCard(
      key: const Key('chatTakeover'),
      accent: colors.info,
      icon: Icons.front_hand_outlined,
      title: l10n.botNeedsHelp(botName),
      body: Text(entry.reason, style: context.textTheme.bodyMedium?.copyWith(height: 1.4)),
      footer: entry.outcome != null
          ? _Outcome(
              text: switch (entry.outcome) { 'completed' => l10n.takeoverCompleted, 'dismissed' => l10n.takeoverDismissed, _ => l10n.expired },
              color: entry.outcome == 'completed' ? colors.positive : context.colorScheme.onSurfaceVariant,
              icon: entry.outcome == 'completed' ? Icons.check_circle_rounded : Icons.do_not_disturb_on_outlined,
            )
          : Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                key: const Key('chatTakeControl'),
                onPressed: onOpen,
                icon: const Icon(Icons.live_tv_rounded, size: 18),
                label: Text(l10n.takeControl),
              ),
            ),
    );
  }
}

class _Outcome extends StatelessWidget {
  const _Outcome({required this.text, required this.color, required this.icon});
  final String text;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Row(children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 6),
        Text(text, style: context.textTheme.labelLarge?.copyWith(color: color, fontWeight: FontWeight.w700)),
      ]).appCardEntrance();
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({super.key, required this.accent, required this.icon, required this.title, required this.body, required this.footer, this.subtitle, this.badge});
  final Color accent;
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? badge;
  final Widget body;
  final Widget footer;

  @override
  Widget build(BuildContext context) {
    final dark = context.isDark;
    return Container(
      padding: const EdgeInsets.all(AppSpace.md),
      decoration: BoxDecoration(
        color: Color.alphaBlend(accent.withValues(alpha: dark ? 0.08 : 0.05), context.colorScheme.surfaceContainerLow),
        borderRadius: AppRadius.cardAll,
        border: Border.all(color: accent.withValues(alpha: dark ? 0.35 : 0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(color: accent.withValues(alpha: dark ? 0.22 : 0.14), borderRadius: BorderRadius.circular(AppRadius.icon)),
            alignment: Alignment.center,
            child: Icon(icon, size: 19, color: accent),
          ),
          const SizedBox(width: AppSpace.sm),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700, height: 1.3)),
              if (subtitle != null || badge != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Wrap(spacing: AppSpace.xs, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
                    ?badge,
                    if (subtitle != null)
                      Text(subtitle!, style: context.textTheme.bodySmall?.copyWith(color: context.colorScheme.onSurfaceVariant)),
                  ]),
                ),
            ]),
          ),
        ]),
        const SizedBox(height: AppSpace.sm),
        body,
        const SizedBox(height: AppSpace.sm),
        footer,
      ]),
    );
  }
}
