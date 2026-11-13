import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/number_format.dart';
import '../../../core/providers.dart';
import '../../../core/widgets.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../theme/app_colors.dart';
import '../../../core/backend.dart';
import '../../../theme/app_tokens.dart';
import '../../files/file_preview.dart';
import '../../settings/totp_scan.dart';
import '../../../ui/tool_words.dart';
import '../../../ui/bot_avatar.dart';
import '../../../ui/motion.dart';
import '../chat_controller.dart';
import '../read_aloud.dart';
import '../media/attachment_view.dart';
import 'chat_markdown.dart';
import 'mentions.dart';
import 'message_actions.dart';
import 'shared_files.dart';
import '../../../ui/action_buttons.dart';
import '../../../ui/glow_button.dart';
import '../../devices/device_labels.dart';
import '../../inbox/for_you.dart';
import 'package:casama_sdk/casama_sdk.dart';
import '../../../ui/effects.dart';

// ---------------------------------------------------------------------------------------------
// Messages

/// What you wrote: a bubble on the right in the accent tint, the tail corner tucked in, with any
/// attached files above it.
class UserBubble extends StatelessWidget {
  const UserBubble({
    super.key,
    required this.text,
    this.attachments = const [],
    this.onEdit,
    this.siblingIndex = 1,
    this.siblingCount = 1,
    this.onBranch,
    this.uploading = false,
    this.onResend,
    this.onDiscard,
  });
  final String text;
  final List<AttachmentRef> attachments;

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
    final scheme = context.colorScheme;
    // Opaque, so it reads the same on any wallpaper.
    final base = context.isDark
        ? scheme.surfaceContainerHigh
        : scheme.surfaceContainerLowest;
    return LayoutBuilder(
      builder: (context, constraints) => Align(
        alignment: AlignmentDirectional.centerEnd,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: (constraints.maxWidth * 0.85).clamp(0, 560),
          ),
          child: MessageActions(
            text: text,
            onEdit: onEdit,
            alignEnd: true,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Color.alphaBlend(
                  scheme.primary.withValues(alpha: context.isDark ? 0.3 : 0.16),
                  base,
                ),
                borderRadius: const BorderRadiusDirectional.only(
                  topStart: Radius.circular(20),
                  topEnd: Radius.circular(20),
                  bottomStart: Radius.circular(20),
                  bottomEnd: Radius.circular(6),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: context.isDark ? 0.2 : 0.05,
                    ),
                    blurRadius: 6,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpace.md,
                  vertical: 11,
                ),
                child: Builder(
                  builder: (context) {
                    final style = context.textTheme.bodyLarge?.copyWith(height: 1.4);
                    // In a group chat, @mentions of its bots stand out (D-118).
                    final mentions = MentionScope.maybeOf(context);
                    if (mentions == null) return Text(text, style: style);
                    return Text.rich(
                      TextSpan(children: mentionSpans(mentions, text, style)),
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

class AssistantMessage extends StatelessWidget {
  const AssistantMessage({
    super.key,
    required this.entry,
    this.onSpeak,
    this.status,
  });
  final MessageEntry entry;
  final VoidCallback? onSpeak;

  /// What the bot is doing while the reply is still empty.
  final String? status;

  @override
  Widget build(BuildContext context) {
    if (entry.text.isEmpty && entry.streaming) {
      return WorkingIndicator(status: status ?? context.l10n.thinking);
    }
    // Media the reply made (a generated image or video, D-205) shows under its text.
    final media = entry.attachments;
    if (entry.text.isEmpty && media.isNotEmpty) {
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
      decoration: BoxDecoration(
        color: context.isDark
            ? scheme.surfaceContainer
            : scheme.surfaceContainerLowest,
        borderRadius: const BorderRadiusDirectional.only(
          topStart: Radius.circular(6),
          topEnd: Radius.circular(20),
          bottomStart: Radius.circular(20),
          bottomEnd: Radius.circular(20),
        ),
        border: Border.all(
          color: reading
              ? scheme.primary.withValues(alpha: 0.6)
              : context.appColors.hairline,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: context.isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
          BoxShadow(
            color: scheme.primary.withValues(alpha: reading ? 0.2 : 0),
            blurRadius: 18,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.md,
          AppSpace.sm,
          AppSpace.md,
          AppSpace.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Once finished, file links that show as cards under the reply leave the text.
            ChatMarkdown(data: entry.streaming ? entry.text : (_shownText[entry] ??= textWithoutSharedLinks(entry.text, alreadyShown: entry.attachments)), selectable: false),
            // Its own layer: the dots animate every frame without repainting the reply's text.
            if (entry.streaming) ...[
              const SizedBox(height: AppSpace.xs),
              RepaintBoundary(child: _TypingDots(color: scheme.primary)),
            ],
          ],
        ),
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
                  markdown: true,
                  onSpeak: onSpeak,
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

/// What the bot is doing right now, over a shimmering placeholder for the reply.
class WorkingIndicator extends StatelessWidget {
  const WorkingIndicator({super.key, required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final still = MediaQuery.disableAnimationsOf(context);
    Widget sparkle = Icon(
      LucideIcons.sparkles,
      size: 18,
      color: scheme.primary,
    );
    Widget text = Text(
      status,
      key: ValueKey(status),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: context.textTheme.bodyMedium?.copyWith(
        color: scheme.onSurfaceVariant,
        fontWeight: FontWeight.w500,
      ),
    );
    if (!still) {
      sparkle = Pulse(
        from: 0.8,
        to: 1.1,
        fadeFrom: 0.55,
        duration: const Duration(milliseconds: 700),
        child: sparkle,
      );
      text = Shimmer(
        key: ValueKey(status),
        color: scheme.primary.withValues(alpha: 0.7),
        child: text,
      );
    }
    return Semantics(
      liveRegion: true,
      label: status,
      // One line, no skeleton: it comes and goes between steps without pushing the chat around.
      child: ExcludeSemantics(
        child: Row(
          children: [
            sparkle,
            const SizedBox(width: AppSpace.xs),
            Flexible(
              child: AnimatedSwitcher(
                duration: AppMotion.of(context, AppMotion.fast),
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
  });
  final NoticeEntry entry;

  /// A computer that broke (state "error", D-240): restart it here, or open its fixes.
  final VoidCallback? onRestartComputer;
  final VoidCallback? onFixComputer;

  /// "Saved to your profile" (D-169): takes the fact back out.
  final void Function(String factId)? onUndo;

  /// Simple chats (D-162): a failure without a plain explanation reads as one sentence; the
  /// technical part stays in Details.
  final bool plain;
  final void Function(String checkpointId)? onRestore;

  /// Failures open their details (error, failed steps, copy and export).
  final VoidCallback? onDetails;

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
    final broken = entry.kind == NoticeKind.computer && entry.text == 'error' && (onRestartComputer != null || onFixComputer != null);
    return Center(
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          key: details ? const Key('errorDetails') : null,
          onTap: details ? onDetails : null,
          borderRadius: BorderRadius.circular(
            failed ? AppRadius.row : AppRadius.pill,
          ),
          child: Container(
            padding: EdgeInsets.fromLTRB(
              12,
              restorable || broken ? 2 : 6,
              restorable || details || broken ? 4 : 12,
              restorable || broken ? 2 : 6,
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

  Future<void> _decide(bool approve, {bool always = false}) async {
    HapticFeedback.mediumImpact();
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
    final muted = context.colorScheme.onSurfaceVariant;
    return _ActionCard(
      key: const Key('chatApproval'),
      accent: high ? colors.negative : context.colorScheme.primary,
      icon: words.icon,
      title: words.doing,
      subtitle: l10n.approvalAsking(widget.botName),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (focus != null)
            Text(
              focus,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.bodyMedium?.copyWith(height: 1.4),
            ),
          if (high)
            Padding(
              padding: const EdgeInsets.only(top: AppSpace.xs),
              child: Row(
                children: [
                  Icon(
                    LucideIcons.triangleAlert,
                    size: 15,
                    color: colors.negative,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      l10n.approvalLookClosely,
                      style: context.textTheme.labelMedium?.copyWith(
                        color: colors.negative,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          _TechnicalDetails(tool: e.tool, args: e.args),
        ],
      ),
      footer: ActionButtons(
        actions: [
          OutlinedButton(
            key: const Key('chatDeny'),
            onPressed: _busy ? null : () => _decide(false),
            child: Text(l10n.notNow),
          ),
          GlowButton(
            key: const Key('chatApprove'),
            onPressed: _busy ? null : () => _decide(true),
            child: Text(l10n.allow),
          ),
        ],
        extra: [
          TextButton(
            key: const Key('chatAlwaysAllow'),
            onPressed: _busy ? null : () => _decide(true, always: true),
            style: TextButton.styleFrom(
              foregroundColor: muted,
              visualDensity: VisualDensity.compact,
            ),
            child: Text(l10n.alwaysAllow),
          ),
        ],
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
    return _ActionCard(
      key: const Key('chatSecret'),
      accent: colors.warning,
      icon: LucideIcons.keyRound,
      title: e.totp
          ? l10n.totpRequestTitle(widget.botName, e.service)
          : l10n.secretRequestTitle(widget.botName, e.service),
      subtitle: l10n.secretRequestHosts(e.hosts.join(', ')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpace.sm,
        children: [
          if (e.reason.isNotEmpty)
            Text(
              e.reason,
              style: context.textTheme.bodyMedium?.copyWith(height: 1.4),
            ),
          TextField(
              key: const Key('secretValue'),
              controller: _value,
              obscureText: _obscure,
              autocorrect: false,
              enableSuggestions: false,
              enableIMEPersonalizedLearning: false,
              keyboardType: TextInputType.visiblePassword,
              autofillHints: const <String>[],
              decoration: InputDecoration(
                labelText: e.totp
                    ? '${e.name} · ${l10n.totpSeedLabel}'
                    : e.name,
                helperText: e.totp ? l10n.totpSeedHelp : l10n.secretRequestHelp,
                prefixIcon: const Icon(LucideIcons.lock, size: 18),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (e.totp)
                      TotpScanButton(
                        onScanned: (link) => setState(() => _value.text = link),
                      ),
                    IconButton(
                      tooltip: _obscure ? l10n.show : l10n.hide,
                      icon: Icon(
                        _obscure ? LucideIcons.eye : LucideIcons.eyeOff,
                        size: 18,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ],
                ),
              ),
              onSubmitted: (_) => _busy ? null : _answer(true),
            ),
        ],
      ),
      footer: ActionButtons(
        actions: [
          OutlinedButton(
            key: const Key('secretDecline'),
            onPressed: _busy ? null : () => _answer(false),
            child: Text(l10n.decline),
          ),
          GlowButton.icon(
            key: const Key('secretSave'),
            onPressed: _busy ? null : () => _answer(true),
            icon: const Icon(LucideIcons.lock, size: 18),
            label: Text(l10n.save),
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

class _DeviceAccessPromptState extends ConsumerState<DeviceAccessPrompt> {
  bool? _allowed;
  var _busy = false;

  @override
  void initState() {
    super.initState();
    // Already allowed (from an earlier card or Settings): show it as done.
    unawaited(
      ref
          .read(backendProvider)
          .deviceGrants(botId: widget.entry.botId)
          .then((g) {
            if (mounted && g.any((x) => x.kind == widget.entry.kind)) {
              setState(() => _allowed ??= true);
            }
          })
          .catchError((_) {}),
    );
  }

  Future<void> _answer(bool allow) async {
    if (!allow) return setState(() => _allowed = false);
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
    required this.accent,
    required this.icon,
    required this.title,
    required this.body,
    required this.footer,
    this.subtitle,
  });
  final Color accent;
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget body;
  final Widget footer;

  @override
  Widget build(BuildContext context) {
    final dark = context.isDark;
    return Container(
      padding: const EdgeInsets.all(AppSpace.md),
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          accent.withValues(alpha: dark ? 0.08 : 0.05),
          context.colorScheme.surfaceContainerLow,
        ),
        borderRadius: AppRadius.cardAll,
        border: Border.all(color: accent.withValues(alpha: dark ? 0.35 : 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: dark ? 0.22 : 0.14),
                  borderRadius: BorderRadius.circular(AppRadius.icon),
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 19, color: accent),
              ),
              const SizedBox(width: AppSpace.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: context.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                    ),
                    if (subtitle != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Wrap(
                          spacing: AppSpace.xs,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            if (subtitle != null)
                              Text(
                                subtitle!,
                                style: context.textTheme.bodySmall?.copyWith(
                                  color: context.colorScheme.onSurfaceVariant,
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.sm),
          body,
          const SizedBox(height: AppSpace.sm),
          footer,
        ],
      ),
    );
  }
}

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

  Future<void> _accept() async {
    setState(() => _busy = true);
    final r = await runGuarded(context, () => ref.read(backendProvider).acceptSuggestion(widget.entry.suggestion.id));
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (r != null) _accepted = true;
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

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final s = widget.entry.suggestion;
    final open = ref.watch(forYouProvider).value?.suggestions;
    // For you lists at most 30; a full list can't say a missing one is closed.
    final pending = open == null || open.length >= 30 ? null : open.map((x) => x.id).toSet();
    // The topic this card opened, when it was accepted.
    final topic = (ref.watch(conversationsProvider(widget.botId)).value ?? const <Conversation>[])
        .where((c) => c.anchorMessageId == widget.entry.messageId)
        .firstOrNull;
    final handled = _accepted != null || topic != null || (pending != null && !pending.contains(s.id));
    if (handled) {
      if (topic != null || _accepted == true) {
        return Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            key: Key('suggestionTopic-${s.id}'),
            icon: Icon(LucideIcons.messagesSquare, size: 16, color: colors.positive),
            label: Text(l10n.suggestionInTopic(s.title), maxLines: 1, overflow: TextOverflow.ellipsis),
            onPressed: topic == null ? null : () => widget.onOpenTopic(topic.id),
          ),
        );
      }
      return _Folded(
        key: Key('suggestionDone-${s.id}'),
        text: l10n.suggestionClosed(s.title),
        color: context.colorScheme.onSurfaceVariant,
        icon: LucideIcons.circleMinus,
      );
    }
    return _ActionCard(
      key: Key('suggestionCard-${s.id}'),
      accent: colors.working,
      icon: LucideIcons.sparkles,
      title: s.title,
      body: s.body.trim().isEmpty
          ? const SizedBox.shrink()
          : Text(s.body.trim(), maxLines: 6, overflow: TextOverflow.ellipsis, style: context.textTheme.bodyMedium?.copyWith(height: 1.4)),
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
