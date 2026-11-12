import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../l10n/generated/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';

/// What a floating message says: news, something that worked, something to fix, or a failure.
enum ToastKind { info, success, warning, error }

/// A floating message of [kind]: a tinted card with the kind's icon and colour, readable over
/// several lines, no wider than [maxWidth] on large screens. [copyText] adds a Copy button (errors
/// pass their full text, technical detail included, so it can be pasted into a bug report).
SnackBar toastSnackBar(
  BuildContext context,
  String message, {
  ToastKind kind = ToastKind.info,
  String? copyText,
  SnackBarAction? action,
  Duration? duration,
  Key? key,
}) {
  final theme = Theme.of(context);
  final style = toastStyle(context, kind);
  final wide = MediaQuery.sizeOf(context).width >= 640;
  return SnackBar(
    key: key,
    behavior: SnackBarBehavior.floating,
    width: wide ? toastMaxWidth : null,
    backgroundColor: style.background,
    elevation: 0,
    padding: EdgeInsets.fromLTRB(14, 10, copyText == null ? 14 : 4, 10),
    shape: RoundedRectangleBorder(
      borderRadius: AppRadius.tileAll,
      side: BorderSide(color: style.border),
    ),
    action: action,
    duration: duration ?? const Duration(milliseconds: 4000),
    content: _ToastContent(
      message: message,
      icon: style.icon,
      accent: style.accent,
      done: style.done,
      textStyle:
          theme.snackBarTheme.contentTextStyle ?? theme.textTheme.bodyMedium,
      copyText: copyText,
    ),
  );
}

/// The widest a floating message gets on a tablet or desktop.
const double toastMaxWidth = 520;

/// The colours and icon for a [ToastKind]. Messages sit on a dark card in both light and dark
/// mode, so the accents come from the dark palette whenever the card is dark.
({Color background, Color border, Color accent, Color done, IconData icon})
toastStyle(BuildContext context, ToastKind kind) {
  final theme = Theme.of(context);
  final scheme = theme.colorScheme;
  final base = theme.snackBarTheme.backgroundColor ?? scheme.inverseSurface;
  final darkCard =
      ThemeData.estimateBrightnessForColor(base) == Brightness.dark;
  final palette = darkCard ? AppColors.dark : AppColors.light;
  final (accent, icon) = switch (kind) {
    ToastKind.info => (
      theme.snackBarTheme.actionTextColor ?? scheme.inversePrimary,
      LucideIcons.info,
    ),
    ToastKind.success => (palette.positive, LucideIcons.circleCheck),
    ToastKind.warning => (palette.warning, LucideIcons.triangleAlert),
    ToastKind.error => (palette.negative, LucideIcons.circleAlert),
  };
  final tint = kind == ToastKind.info ? 0.0 : 0.14;
  return (
    background: Color.alphaBlend(accent.withValues(alpha: tint), base),
    border: accent.withValues(alpha: kind == ToastKind.info ? 0.18 : 0.38),
    accent: accent,
    done: palette.positive,
    icon: icon,
  );
}

class _ToastContent extends StatelessWidget {
  const _ToastContent({
    required this.message,
    required this.icon,
    required this.accent,
    required this.done,
    required this.textStyle,
    this.copyText,
  });

  final String message;
  final IconData icon;
  final Color accent;
  final Color done;
  final TextStyle? textStyle;
  final String? copyText;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(icon, size: 20, color: accent),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(message, style: textStyle?.copyWith(height: 1.35)),
          ),
        ),
        if (copyText != null) ...[
          const SizedBox(width: 4),
          _CopyButton(
            text: copyText!,
            color: (textStyle?.color ?? Colors.white).withValues(alpha: 0.8),
            doneColor: done,
          ),
        ],
      ],
    );
  }
}

/// Copies the message's full text; the icon turns into a check for a moment.
class _CopyButton extends StatefulWidget {
  const _CopyButton({
    required this.text,
    required this.color,
    required this.doneColor,
  });

  final String text;
  final Color color;
  final Color doneColor;

  @override
  State<_CopyButton> createState() => _CopyButtonState();
}

class _CopyButtonState extends State<_CopyButton> {
  bool _copied = false;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.text));
    if (!mounted) return;
    setState(() => _copied = true);
    await Future<void>.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SizedBox(
      width: 32,
      height: 32,
      child: IconButton(
        key: const Key('toastCopy'),
        padding: EdgeInsets.zero,
        iconSize: 16,
        visualDensity: VisualDensity.compact,
        tooltip: _copied ? l10n.copied : l10n.copy,
        onPressed: _copy,
        icon: AnimatedSwitcher(
          duration: const Duration(milliseconds: 160),
          child: Icon(
            _copied ? LucideIcons.check : LucideIcons.copy,
            key: ValueKey(_copied),
            color: _copied ? widget.doneColor : widget.color,
          ),
        ),
      ),
    );
  }
}
