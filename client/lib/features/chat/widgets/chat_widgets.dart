import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:markdown_widget/markdown_widget.dart';

import '../../../core/providers.dart';
import '../../../core/theme.dart';
import '../../../core/widgets.dart';
import '../chat_controller.dart';

/// A chat message. Assistant messages render Markdown with code highlighting.
class MessageBubble extends StatelessWidget {
  const MessageBubble({super.key, required this.entry});
  final MessageEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mine = entry.role == 'user';
    final bg = mine ? theme.colorScheme.primaryContainer : theme.colorScheme.surfaceContainerHighest;
    final fg = mine ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onSurface;
    final dark = theme.brightness == Brightness.dark;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
          child: mine
              ? SelectableText(entry.text, style: TextStyle(color: fg))
              : Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                  if (entry.text.isEmpty && entry.streaming)
                    Text(context.l10n.thinking, style: TextStyle(color: fg.withValues(alpha: 0.7)))
                  else
                    MarkdownBlock(
                      data: entry.text,
                      selectable: true,
                      config: (dark ? MarkdownConfig.darkConfig : MarkdownConfig.defaultConfig),
                    ),
                  if (entry.streaming)
                    const Padding(padding: EdgeInsets.only(top: 6), child: SizedBox(width: 40, child: LinearProgressIndicator())),
                ]),
        ),
      ),
    );
  }
}

String _toolSummary(ToolEntry t) {
  final a = t.args;
  final key = ['command', 'url', 'path', 'query', 'ref', 'label', 'name', 'content'].firstWhere((k) => a[k] != null, orElse: () => '');
  if (key.isEmpty) return '';
  final v = '${a[key]}'.replaceAll('\n', ' ');
  return v.length > 90 ? '${v.substring(0, 87)}...' : v;
}

IconData _toolIcon(String tool) {
  if (tool.startsWith('shell')) return Icons.terminal;
  if (tool.startsWith('files')) return Icons.description_outlined;
  if (tool.startsWith('browser')) return Icons.language;
  if (tool.startsWith('memory')) return Icons.psychology_outlined;
  if (tool.startsWith('skills')) return Icons.menu_book_outlined;
  if (tool.startsWith('checkpoint')) return Icons.restore;
  return Icons.build_outlined;
}

/// A folded, readable card for one tool step; expands to show arguments and output.
class ToolCard extends StatelessWidget {
  const ToolCard({super.key, required this.entry});
  final ToolEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final status = switch (entry.status) {
      ToolStatus.running => l10n.toolRunning,
      ToolStatus.done => l10n.toolDone(entry.durationMs ?? 0),
      ToolStatus.failed => l10n.toolFailedLabel,
    };
    final summary = _toolSummary(entry);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        key: ValueKey(entry.callId),
        dense: true,
        leading: entry.status == ToolStatus.running
            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
            : Icon(
                entry.status == ToolStatus.failed ? Icons.error_outline : _toolIcon(entry.tool),
                color: entry.status == ToolStatus.failed ? theme.colorScheme.error : null,
              ),
        title: Text(entry.tool, style: monoStyle.copyWith(fontWeight: FontWeight.w600)),
        subtitle: Text(
          [summary, status].where((s) => s.isNotEmpty).join(' · '),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SelectableText(const JsonEncoder.withIndent('  ').convert(entry.args), style: monoStyle),
          if (entry.output.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(l10n.toolOutput, style: theme.textTheme.labelMedium),
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(maxHeight: 240),
              decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHigh, borderRadius: BorderRadius.circular(8)),
              child: SingleChildScrollView(reverse: true, child: SelectableText(entry.output, style: monoStyle)),
            ),
          ],
          if (entry.preview != null && entry.output.isEmpty) ...[
            const SizedBox(height: 8),
            SelectableText(entry.preview!, style: theme.textTheme.bodySmall),
          ],
          if (entry.error != null) ...[
            const SizedBox(height: 8),
            SelectableText(entry.error!, style: TextStyle(color: theme.colorScheme.error)),
          ],
        ],
      ),
    );
  }
}

/// A one-line note in the chat (memory saved, skill loaded, checkpoint, computer state, run ended).
class NoticeLine extends StatelessWidget {
  const NoticeLine({super.key, required this.entry, this.onRestore});
  final NoticeEntry entry;
  final void Function(String checkpointId)? onRestore;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final (icon, text, color) = switch (entry.kind) {
      NoticeKind.memory => (Icons.psychology_outlined, l10n.remembered, theme.colorScheme.outline),
      NoticeKind.skill => (Icons.menu_book_outlined, l10n.skillLoaded(entry.text), theme.colorScheme.outline),
      NoticeKind.checkpoint => (Icons.restore, l10n.checkpointSaved(entry.text), theme.colorScheme.outline),
      NoticeKind.computer => (Icons.computer, l10n.computerState(entry.text), theme.colorScheme.outline),
      NoticeKind.failed => (Icons.error_outline, l10n.runFailed(entry.text), theme.colorScheme.error),
      NoticeKind.cancelled => (Icons.stop_circle_outlined, l10n.runCancelled, theme.colorScheme.outline),
      NoticeKind.userControl => (Icons.pan_tool_outlined, l10n.pausedUserInControl, theme.colorScheme.tertiary),
      NoticeKind.botControl => (Icons.smart_toy_outlined, l10n.botBackInControl, theme.colorScheme.outline),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Flexible(child: Text(text, style: theme.textTheme.bodySmall?.copyWith(color: color))),
        if (entry.kind == NoticeKind.checkpoint && entry.refId != null && onRestore != null)
          TextButton(onPressed: () => onRestore!(entry.refId!), child: Text(l10n.restore)),
      ]),
    );
  }
}

/// An approval request inside the chat: approve or deny right where the bot paused.
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
    final theme = Theme.of(context);
    final e = widget.entry;
    final decision = e.decision ?? _localDecision;
    final high = e.risk == 'high';
    return Card(
      key: const Key('chatApproval'),
      color: high ? theme.colorScheme.errorContainer : theme.colorScheme.secondaryContainer,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Icon(high ? Icons.warning_amber : Icons.verified_user_outlined, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(l10n.needsApprovalFor(widget.botName, e.tool), style: theme.textTheme.titleSmall)),
          ]),
          const SizedBox(height: 6),
          Text(
            const JsonEncoder.withIndent('  ').convert(e.args),
            style: theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
            maxLines: 8,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          if (decision != null)
            Text(
              switch (decision) { 'approved' => l10n.approved, 'denied' => l10n.denied, _ => l10n.expired },
              style: theme.textTheme.labelLarge,
            )
          else
            Wrap(alignment: WrapAlignment.end, spacing: 8, children: [
              TextButton(onPressed: _busy ? null : () => _decide(false), child: Text(l10n.deny)),
              TextButton(onPressed: _busy ? null : () => _decide(true, always: true), child: Text(l10n.alwaysAllow)),
              FilledButton(key: const Key('chatApprove'), onPressed: _busy ? null : () => _decide(true), child: Text(l10n.approve)),
            ]),
        ]),
      ),
    );
  }
}

/// A bot asking for a person to take over its screen.
class TakeoverPrompt extends StatelessWidget {
  const TakeoverPrompt({super.key, required this.entry, required this.botName, required this.onOpen});
  final TakeoverEntry entry;
  final String botName;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Card(
      key: const Key('chatTakeover'),
      color: theme.colorScheme.tertiaryContainer,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            const Icon(Icons.front_hand_outlined, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(l10n.botNeedsHelp(botName), style: theme.textTheme.titleSmall)),
          ]),
          const SizedBox(height: 6),
          Text(entry.reason),
          const SizedBox(height: 8),
          if (entry.outcome != null)
            Text(
              switch (entry.outcome) {
                'completed' => l10n.takeoverCompleted,
                'dismissed' => l10n.takeoverDismissed,
                _ => l10n.expired,
              },
              style: theme.textTheme.labelLarge,
            )
          else
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                key: const Key('chatTakeControl'),
                onPressed: onOpen,
                icon: const Icon(Icons.live_tv_outlined),
                label: Text(l10n.takeControl),
              ),
            ),
        ]),
      ),
    );
  }
}
