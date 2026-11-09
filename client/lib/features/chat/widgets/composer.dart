import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/widgets.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_tokens.dart';
import '../../../ui/motion.dart';

/// Hardware keyboards send with Enter and break lines with Shift+Enter.
bool get _enterSends =>
    kIsWeb ||
    defaultTargetPlatform == TargetPlatform.macOS ||
    defaultTargetPlatform == TargetPlatform.windows ||
    defaultTargetPlatform == TargetPlatform.linux;

/// The message field: grows to a few lines, dictation on the left of the send button, and a round
/// send button that turns into Stop while the bot works.
class ChatComposer extends StatelessWidget {
  const ChatComposer({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.hint,
    required this.running,
    required this.onSend,
    required this.onStop,
    required this.recording,
    required this.transcribing,
    required this.onDictate,
    this.attachButton,
    this.attachments,
    this.hasAttachments = false,
    this.uploading = false,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String hint;
  final bool running;
  final VoidCallback onSend;
  final VoidCallback onStop;
  final bool recording;
  final bool transcribing;
  final VoidCallback onDictate;

  /// The "+" button that adds files and photos.
  final Widget? attachButton;

  /// Files waiting to be sent, shown inside the field above the text.
  final Widget? attachments;
  final bool hasAttachments;

  /// Files still uploading: Send waits for them.
  final bool uploading;

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (!_enterSends || event is! KeyDownEvent) return KeyEventResult.ignored;
    final enter = event.logicalKey == LogicalKeyboardKey.enter || event.logicalKey == LogicalKeyboardKey.numpadEnter;
    if (!enter || HardwareKeyboard.instance.isShiftPressed) return KeyEventResult.ignored;
    // An input method still composing (Japanese, Chinese…) owns Enter.
    if (controller.value.composing.isValid) return KeyEventResult.ignored;
    if (!running && !uploading && (controller.text.trim().isNotEmpty || hasAttachments)) onSend();
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    final dark = context.isDark;
    return ListenableBuilder(
      listenable: Listenable.merge([controller, focusNode]),
      builder: (context, _) {
        final canSend = (controller.text.trim().isNotEmpty || hasAttachments) && !uploading;
        final focused = focusNode.hasFocus;
        return AnimatedContainer(
          duration: AppMotion.of(context, AppMotion.fast),
          curve: AppMotion.curve,
          decoration: BoxDecoration(
            color: dark ? scheme.surfaceContainerHigh : scheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: focused ? scheme.primary.withValues(alpha: 0.6) : context.appColors.hairline,
              width: focused ? 1.5 : 1,
            ),
            boxShadow: [
              if (!dark)
                BoxShadow(
                  color: Colors.black.withValues(alpha: focused ? 0.08 : 0.05),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (attachments != null) Padding(padding: const EdgeInsets.fromLTRB(10, 10, 10, 0), child: attachments),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (attachButton != null) Padding(padding: const EdgeInsets.fromLTRB(6, 7, 0, 7), child: attachButton),
                  Expanded(
                    child: Focus(
                      canRequestFocus: false,
                      skipTraversal: true,
                      onKeyEvent: _onKey,
                      child: TextField(
                        key: const Key('messageInput'),
                        controller: controller,
                        focusNode: focusNode,
                        minLines: 1,
                        maxLines: 8,
                        textAlignVertical: TextAlignVertical.center,
                        textCapitalization: TextCapitalization.sentences,
                        keyboardType: TextInputType.multiline,
                        textInputAction: TextInputAction.newline,
                        style: context.textTheme.bodyLarge,
                        decoration: InputDecoration(
                          hintText: recording ? l10n.listening : hint,
                          hintMaxLines: 1,
                          hintStyle: context.textTheme.bodyLarge?.copyWith(
                            color: recording ? context.appColors.negative : scheme.onSurfaceVariant,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          filled: false,
                          isDense: true,
                          contentPadding: EdgeInsets.fromLTRB(attachButton == null ? AppSpace.lg : AppSpace.xs, 15, AppSpace.xs, 15),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 7, 2, 7),
                    child: _DictateButton(recording: recording, transcribing: transcribing, onPressed: onDictate),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 7, 7, 7),
                    child: AnimatedSwitcher(
                      duration: AppMotion.of(context, AppMotion.fast),
                      transitionBuilder: (child, a) => ScaleTransition(
                        scale: a,
                        child: FadeTransition(opacity: a, child: child),
                      ),
                      child: running
                          ? _RoundButton(
                              key: const Key('stopButton'),
                              tooltip: l10n.stop,
                              icon: Icons.stop_rounded,
                              background: scheme.onSurface,
                              foreground: scheme.surface,
                              onPressed: onStop,
                            )
                          : _RoundButton(
                              key: const Key('sendButton'),
                              tooltip: l10n.send,
                              icon: Icons.arrow_upward_rounded,
                              background: scheme.primary,
                              foreground: scheme.onPrimary,
                              onPressed: canSend ? onSend : null,
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DictateButton extends StatelessWidget {
  const _DictateButton({required this.recording, required this.transcribing, required this.onPressed});
  final bool recording;
  final bool transcribing;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    final red = context.appColors.negative;
    Widget icon = transcribing
        ? SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, strokeCap: StrokeCap.round, color: scheme.primary),
          )
        : Icon(recording ? Icons.stop_circle_rounded : Icons.mic_none_rounded, size: 22, color: recording ? red : scheme.onSurfaceVariant);
    if (recording) icon = Pulse(from: 0.9, to: 1.1, duration: const Duration(milliseconds: 600), child: icon);
    return IconButton(
      key: const Key('dictateButton'),
      tooltip: recording ? l10n.stopDictation : l10n.dictate,
      onPressed: transcribing ? null : onPressed,
      icon: icon,
      style: IconButton.styleFrom(
        fixedSize: const Size.square(40),
        minimumSize: const Size.square(40),
        padding: EdgeInsets.zero,
        backgroundColor: recording ? red.withValues(alpha: 0.12) : Colors.transparent,
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    super.key,
    required this.tooltip,
    required this.icon,
    required this.background,
    required this.foreground,
    required this.onPressed,
  });
  final String tooltip;
  final IconData icon;
  final Color background;
  final Color foreground;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed == null
          ? null
          : () {
              HapticFeedback.lightImpact();
              onPressed!();
            },
      icon: Icon(icon, size: 22),
      style: IconButton.styleFrom(
        fixedSize: const Size.square(40),
        minimumSize: const Size.square(40),
        padding: EdgeInsets.zero,
        backgroundColor: background,
        foregroundColor: foreground,
        disabledBackgroundColor: scheme.onSurface.withValues(alpha: 0.08),
        disabledForegroundColor: scheme.onSurface.withValues(alpha: 0.32),
      ),
    );
  }
}
