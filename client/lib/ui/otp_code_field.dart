import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';

/// Six boxes for a one-time code: the email sign-in code and an authenticator app.
///
/// One real text field covers the boxes, so paste, the SMS code suggestion and a
/// hardware keyboard fill them the same way typing does. The sixth digit calls
/// [onCompleted]. [invalid] shakes the row and, if those digits are still there
/// when the shake ends, clears them so the next code can be typed immediately.
class OtpCodeField extends StatefulWidget {
  const OtpCodeField({
    super.key,
    required this.controller,
    this.onCompleted,
    this.onChanged,
    this.onSubmitted,
    this.label,
    this.autofocus = true,
    this.enabled = true,
    this.invalid = false,
  });

  static const length = 6;

  final TextEditingController controller;
  final ValueChanged<String>? onCompleted;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onSubmitted;

  /// Read to assistive tech. The boxes themselves are the visible label.
  final String? label;
  final bool autofocus;
  final bool enabled;
  final bool invalid;

  @override
  State<OtpCodeField> createState() => _OtpCodeFieldState();
}

class _OtpCodeFieldState extends State<OtpCodeField>
    with SingleTickerProviderStateMixin {
  static const _cellWidth = 48.0;
  static const _cellHeight = 56.0;
  static const _gap = 8.0;

  /// Wider than [_gap] so the code reads as two groups of three.
  static const _split = 28.0;
  static const _rowWidth =
      _cellWidth * OtpCodeField.length +
      _gap * (OtpCodeField.length - 2) +
      _split;

  final _focus = FocusNode();
  late final AnimationController _shake;

  /// The last six digits we already submitted, so a rebuild doesn't send them again.
  String? _sent;
  var _rejectGeneration = 0;

  @override
  void initState() {
    super.initState();
    _focus.addListener(_redraw);
    widget.controller.addListener(_onController);
    _shake = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _shake.duration = AppMotion.of(context, const Duration(milliseconds: 420));
  }

  @override
  void didUpdateWidget(OtpCodeField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onController);
      widget.controller.addListener(_onController);
    }
    if (widget.invalid && !oldWidget.invalid) {
      // After this frame, so focus and the shake aren't started mid-build.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && widget.invalid) _reject();
      });
    }
  }

  @override
  void dispose() {
    _focus.removeListener(_redraw);
    _focus.dispose();
    widget.controller.removeListener(_onController);
    _shake.dispose();
    super.dispose();
  }

  void _redraw() {
    if (mounted) setState(() {});
  }

  void _onController() {
    if (widget.controller.text.length < OtpCodeField.length) _sent = null;
  }

  void _reject() {
    final generation = ++_rejectGeneration;
    final rejected = widget.controller.text;
    HapticFeedback.mediumImpact();
    _focus.requestFocus();
    if (rejected.isNotEmpty) {
      widget.controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: rejected.length,
      );
    }
    _shake.forward(from: 0).then((_) {
      if (!mounted || generation != _rejectGeneration || !widget.invalid) {
        return;
      }
      // They already started the next code (or deleted this one). Leave it.
      if (widget.controller.text != rejected || rejected.isEmpty) return;
      widget.controller.clear();
      _sent = null;
      setState(() {});
    });
  }

  void _changed(String text) {
    if (text.length < OtpCodeField.length) _sent = null;
    setState(() {});
    widget.onChanged?.call(text);
    if (widget.enabled && text.length == OtpCodeField.length && text != _sent) {
      _sent = text;
      HapticFeedback.lightImpact();
      widget.onCompleted?.call(text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = widget.controller.text;
    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: AnimatedBuilder(
          animation: _shake,
          builder: (context, child) {
            final t = _shake.value;
            final dx = math.sin(t * math.pi * 5) * (1 - t) * 8;
            return Transform.translate(offset: Offset(dx, 0), child: child);
          },
          child: SizedBox(
            width: _rowWidth,
            height: _cellHeight,
            child: Stack(
              alignment: Alignment.center,
              children: [
                ExcludeSemantics(
                  child: Row(
                    children: [
                      for (var i = 0; i < OtpCodeField.length; i++) ...[
                        if (i == 3)
                          _splitMark(context)
                        else if (i > 0)
                          const SizedBox(width: _gap),
                        _OtpCell(
                          key: ValueKey('otp-cell-$i'),
                          digit: i < text.length ? text[i] : null,
                          active:
                              widget.enabled &&
                              _focus.hasFocus &&
                              i == text.length &&
                              text.length < OtpCodeField.length,
                          invalid: widget.invalid,
                        ),
                      ],
                    ],
                  ),
                ),
                Positioned.fill(child: _field(context)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _splitMark(BuildContext context) {
    return SizedBox(
      width: _split,
      child: Center(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: context.colorScheme.onSurfaceVariant.withValues(alpha: 0.45),
            shape: BoxShape.circle,
          ),
          child: const SizedBox(width: 4, height: 4),
        ),
      ),
    );
  }

  Widget _field(BuildContext context) {
    return TextSelectionTheme(
      data: const TextSelectionThemeData(
        selectionColor: Colors.transparent,
        cursorColor: Colors.transparent,
      ),
      child: Semantics(
        label: widget.label,
        child: TextField(
          controller: widget.controller,
          focusNode: _focus,
          autofocus: widget.autofocus,
          enabled: widget.enabled,
          showCursor: false,
          cursorWidth: 0,
          enableInteractiveSelection: true,
          enableSuggestions: false,
          autocorrect: false,
          smartDashesType: SmartDashesType.disabled,
          smartQuotesType: SmartQuotesType.disabled,
          enableIMEPersonalizedLearning: false,
          stylusHandwritingEnabled: false,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.transparent,
            fontSize: 20,
            height: 1,
          ),
          autofillHints: const [AutofillHints.oneTimeCode],
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(OtpCodeField.length),
          ],
          // No decorator: its fill and outline would paint over the boxes.
          decoration: null,
          onChanged: _changed,
          onSubmitted: (_) => widget.onSubmitted?.call(),
        ),
      ),
    );
  }
}

class _OtpCell extends StatelessWidget {
  const _OtpCell({
    super.key,
    required this.digit,
    required this.active,
    required this.invalid,
  });

  final String? digit;
  final bool active;
  final bool invalid;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    final base = dark ? scheme.surfaceContainer : scheme.surfaceContainerLowest;
    final accent = invalid ? scheme.error : scheme.primary;
    final emphasized = active || invalid;
    final fill = emphasized
        ? Color.alphaBlend(accent.withValues(alpha: dark ? 0.22 : 0.14), base)
        : base;
    return AnimatedContainer(
      duration: AppMotion.of(context, AppMotion.fast),
      curve: AppMotion.curve,
      width: _OtpCodeFieldState._cellWidth,
      height: _OtpCodeFieldState._cellHeight,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: emphasized ? accent : context.appColors.hairline,
          width: emphasized ? 1.5 : 1,
        ),
      ),
      child: digit != null
          ? TweenAnimationBuilder<double>(
              key: ValueKey(digit),
              tween: Tween(begin: 0.86, end: 1),
              duration: AppMotion.of(
                context,
                const Duration(milliseconds: 140),
              ),
              curve: AppMotion.curve,
              builder: (_, scale, child) =>
                  Transform.scale(scale: scale, child: child),
              child: Text(
                digit!,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  height: 1,
                  fontFeatures: AppText.tabular,
                  color: invalid ? scheme.error : scheme.onSurface,
                ),
              ),
            )
          : active
          ? Container(
              width: 2,
              height: 24,
              decoration: BoxDecoration(
                color: invalid ? scheme.error : scheme.primary,
                borderRadius: BorderRadius.circular(1),
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}
