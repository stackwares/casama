import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:pasteboard/pasteboard.dart';

import '../../../core/widgets.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_tokens.dart';
import '../../../ui/glass.dart';
import '../../../ui/motion.dart';

/// Hardware keyboards send with Enter and break lines with Shift+Enter.
bool get _enterSends =>
    kIsWeb || defaultTargetPlatform == TargetPlatform.macOS || defaultTargetPlatform == TargetPlatform.windows || defaultTargetPlatform == TargetPlatform.linux;

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
    this.onDevice = false,
    this.attachButton,
    this.attachments,
    this.hasAttachments = false,
    this.uploading = false,
    this.keyHandler,
    this.allowSendWhileRunning = true,
    this.onPasteImage,
  });

  /// A picture pasted with Cmd/Ctrl+V on a keyboard (desktop and the web, Add 11): attached like a
  /// picked photo. Text on the clipboard still pastes into the field as usual.
  final ValueChanged<Uint8List>? onPasteImage;

  /// Reads a picture from the clipboard; tests replace it.
  @visibleForTesting
  static Future<Uint8List?> Function() readClipboardImage = () => Pasteboard.image;

  /// Off where a message can't join a run in progress (group chats start one run per bot).
  final bool allowSendWhileRunning;

  /// Asked first about each key (group chats' @-mention suggestions take Tab, Enter and arrows).
  final KeyEventResult Function(KeyEvent event)? keyHandler;

  final TextEditingController controller;
  final FocusNode focusNode;
  final String hint;
  final bool running;
  final VoidCallback onSend;
  final VoidCallback onStop;
  final bool recording;
  final bool transcribing;
  final VoidCallback onDictate;

  /// The mic uses the device's own recognizer (the server's dictation failed or isn't set up).
  final bool onDevice;

  /// The "+" button that adds files and photos.
  final Widget? attachButton;

  /// Files waiting to be sent, shown inside the field above the text.
  final Widget? attachments;
  final bool hasAttachments;

  /// Files still uploading: Send waits for them.
  final bool uploading;

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    final first = keyHandler?.call(event) ?? KeyEventResult.ignored;
    if (first != KeyEventResult.ignored) return first;
    final paste = onPasteImage;
    if (paste != null && event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.keyV && (HardwareKeyboard.instance.isMetaPressed || HardwareKeyboard.instance.isControlPressed)) {
      // Not handled here, so text still pastes; a picture on the clipboard is attached as well.
      readClipboardImage().then((bytes) {
        if (bytes != null && bytes.isNotEmpty) paste(bytes);
      }).catchError((_) {});
      return KeyEventResult.ignored;
    }
    if (!_enterSends || event is! KeyDownEvent) return KeyEventResult.ignored;
    final enter = event.logicalKey == LogicalKeyboardKey.enter || event.logicalKey == LogicalKeyboardKey.numpadEnter;
    if (!enter || HardwareKeyboard.instance.isShiftPressed) return KeyEventResult.ignored;
    // An input method still composing (Japanese, Chinese…) owns Enter.
    if (controller.value.composing.isValid) return KeyEventResult.ignored;
    // While the bot works, Enter still sends: the message joins what it's doing.
    if ((!running || allowSendWhileRunning) && !uploading && (controller.text.trim().isNotEmpty || hasAttachments)) onSend();
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
        // While dictating, Send finishes the dictation and sends it, so it never turns into Stop.
        final canSend = (controller.text.trim().isNotEmpty || hasAttachments || recording) && !uploading;
        final focused = focusNode.hasFocus;
        // The mic and send buttons are 40pt inside 7pt of padding, but on phones Material pads
        // each to a 48pt tap target, so the row is 62pt there and 54pt on desktop. The line is
        // the font's own size, padded equally so the hint and the text share the buttons' center.
        final textStyle = (context.textTheme.bodyLarge ?? const TextStyle(fontSize: 16)).copyWith(
          height: 1,
          leadingDistribution: TextLeadingDistribution.even,
        );
        final buttonBox = Theme.of(context).materialTapTargetSize == MaterialTapTargetSize.padded ? 48.0 : 40.0;
        final vertical = (buttonBox + 14 - (textStyle.fontSize ?? 16)) / 2;
        // Frosted over the wallpaper; the border lights up with focus.
        return Glass(
          borderRadius: BorderRadius.circular(26),
          opacity: dark ? 0.78 : 0.86,
          border: Border.all(color: focused ? scheme.primary.withValues(alpha: 0.6) : context.appColors.hairline, width: focused ? 1.5 : 1),
          child: AnimatedContainer(
            duration: AppMotion.of(context, AppMotion.fast),
            curve: AppMotion.curve,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
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
                          style: textStyle,
                          decoration: InputDecoration(
                            hintText: recording ? l10n.listening : hint,
                            hintMaxLines: 1,
                            hintStyle: textStyle.copyWith(color: recording ? context.appColors.negative : scheme.onSurfaceVariant),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            filled: false,
                            isCollapsed: true,
                            visualDensity: VisualDensity.standard,
                            contentPadding: EdgeInsets.fromLTRB(attachButton == null ? AppSpace.lg : AppSpace.xs, vertical, AppSpace.xs, vertical),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(0, 7, 2, 7),
                      child: _DictateButton(recording: recording, transcribing: transcribing, onDevice: onDevice, onPressed: onDictate),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(0, 7, 7, 7),
                      child: AnimatedSwitcher(
                        duration: AppMotion.of(context, AppMotion.fast),
                        transitionBuilder: (child, a) => ScaleTransition(
                          scale: a,
                          child: FadeTransition(opacity: a, child: child),
                        ),
                        // Working: Stop, until there's something typed; then Send (it joins the task).
                        child: running && (!canSend || !allowSendWhileRunning)
                            ? _StopButton(key: const Key('stopButton'), tooltip: l10n.stop, onPressed: onStop)
                            : _RoundButton(
                                key: const Key('sendButton'),
                                tooltip: l10n.send,
                                icon: LucideIcons.arrowUp,
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
          ),
        );
      },
    );
  }
}

class _DictateButton extends StatelessWidget {
  const _DictateButton({required this.recording, required this.transcribing, required this.onDevice, required this.onPressed});
  final bool recording;
  final bool onDevice;
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
        : Icon(recording ? LucideIcons.circleStop : LucideIcons.mic, size: 22, color: recording ? red : scheme.onSurfaceVariant);
    if (recording) icon = Pulse(from: 0.9, to: 1.1, duration: const Duration(milliseconds: 600), child: icon);
    return IconButton(
      key: const Key('dictateButton'),
      tooltip: recording
          ? (onDevice ? l10n.stopListening : l10n.stopDictation)
          : (onDevice ? l10n.dictateOnDevice : l10n.dictate),
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

/// Stop while the bot works: a small filled square without a circle, sized like the mic beside it.
class _StopButton extends StatelessWidget {
  const _StopButton({super.key, required this.tooltip, required this.onPressed});
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    return IconButton(
      tooltip: tooltip,
      onPressed: () {
        HapticFeedback.lightImpact();
        onPressed();
      },
      icon: Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(color: scheme.onSurface, borderRadius: BorderRadius.circular(3.5)),
      ),
      style: IconButton.styleFrom(
        fixedSize: const Size.square(40),
        minimumSize: const Size.square(40),
        padding: EdgeInsets.zero,
        backgroundColor: Colors.transparent,
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({super.key, required this.tooltip, required this.icon, required this.background, required this.foreground, required this.onPressed});
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
