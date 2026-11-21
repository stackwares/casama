import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

import '../../../theme/app_tokens.dart';
import '../../../ui/shell_layout.dart';
import '../../../ui/screen_tile.dart';

/// Debug builds only: the screen card with a sample screen, to try its size, corners and states
/// on a phone before it's wired to real pictures (SCREEN-CARD-PLAN Phase 0). Turn it on with
/// `?previewScreenCard=1` on the web or `--dart-define=PREVIEW_SCREEN_CARD=1` on a device.
final bool screenCardPreview =
    kDebugMode && (Uri.base.queryParameters.containsKey('previewScreenCard') || const {'1', 'true'}.contains(_previewDefine));

const _previewDefine = String.fromEnvironment('PREVIEW_SCREEN_CARD');

/// How wide the card is: 38% of the chat on phones, between 132 and 168 points; 220 on tablets.
double screenCardWidth(double chatWidth, LayoutSize layout) => layout == LayoutSize.phone ? (chatWidth * 0.38).clamp(132.0, 168.0) : 220.0;

/// The sample card over a chat's thread. A tap moves to the next state, as does each 4 seconds;
/// the close button hides it for 5 seconds.
class ScreenCardPreview extends StatefulWidget {
  const ScreenCardPreview({super.key, required this.botName, required this.layout});
  final String botName;
  final LayoutSize layout;

  @override
  State<ScreenCardPreview> createState() => _ScreenCardPreviewState();
}

class _ScreenCardPreviewState extends State<ScreenCardPreview> {
  static const _order = [
    ScreenTileState.watching,
    ScreenTileState.needsYou,
    ScreenTileState.held,
    ScreenTileState.stale,
    ScreenTileState.done,
  ];
  var _i = 0;
  var _shown = true;
  Timer? _cycle;
  Timer? _back;

  @override
  void initState() {
    super.initState();
    _startCycle();
  }

  void _startCycle() {
    _cycle?.cancel();
    _cycle = Timer.periodic(const Duration(seconds: 4), (_) => _next());
  }

  void _next() {
    if (mounted) setState(() => _i = (_i + 1) % _order.length);
  }

  void _close() {
    setState(() => _shown = false);
    _back?.cancel();
    _back = Timer(const Duration(seconds: 5), () {
      if (mounted) setState(() => _shown = true);
    });
  }

  @override
  void dispose() {
    _cycle?.cancel();
    _back?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final width = screenCardWidth(box.maxWidth, widget.layout);
        final state = _order[_i];
        return ScreenTileCorner(
          width: width,
          insets: const EdgeInsets.all(AppSpace.sm),
          // It grows from the header's monitor button (top right) and folds back into it.
          child: AnimatedScale(
            scale: _shown ? 1 : 0.2,
            alignment: Alignment.topRight,
            duration: AppMotion.of(context, AppMotion.duration),
            curve: AppMotion.curve,
            child: AnimatedOpacity(
              opacity: _shown ? 1 : 0,
              duration: AppMotion.of(context, AppMotion.fast),
              child: IgnorePointer(
                ignoring: !_shown,
                child: ScreenTile(
                  picture: _SampleScreen(frozen: state != ScreenTileState.watching && state != ScreenTileState.needsYou),
                  state: state,
                  botName: widget.botName,
                  onTap: () {
                    _next();
                    _startCycle();
                  },
                  onClose: _close,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// A made-up web page with a pointer that moves once a second, as real pictures would.
class _SampleScreen extends StatefulWidget {
  const _SampleScreen({required this.frozen});
  final bool frozen;

  @override
  State<_SampleScreen> createState() => _SampleScreenState();
}

class _SampleScreenState extends State<_SampleScreen> {
  static const _spots = [Offset(0.22, 0.5), Offset(0.5, 0.5), Offset(0.78, 0.5), Offset(0.5, 0.86), Offset(0.62, 0.1)];
  var _frame = 0;
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && !widget.frozen) setState(() => _frame++);
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final spot = _spots[_frame % _spots.length];
    final picked = _frame % _spots.length;
    return ColoredBox(
      color: Colors.white,
      child: LayoutBuilder(
        builder: (context, box) {
          final w = box.maxWidth, h = box.maxHeight;
          Widget bar(double width, {Color color = const Color(0xFFD7DAE0), double height = 4}) => Container(
            width: width,
            height: height,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
          );
          return Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: h * 0.13,
                    color: const Color(0xFFEEF0F3),
                    padding: EdgeInsets.symmetric(horizontal: w * 0.18, vertical: h * 0.035),
                    child: Container(
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(w * 0.06, h * 0.06, w * 0.06, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        bar(w * 0.5, color: const Color(0xFF2F5BEA), height: h * 0.07),
                        SizedBox(height: h * 0.05),
                        Row(
                          children: [
                            for (var k = 0; k < 3; k++) ...[
                              if (k > 0) SizedBox(width: w * 0.03),
                              Container(
                                width: w * 0.26,
                                height: h * 0.26,
                                decoration: BoxDecoration(
                                  color: k == picked ? const Color(0xFFDDE6FF) : const Color(0xFFF1F3F6),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ],
                          ],
                        ),
                        SizedBox(height: h * 0.06),
                        bar(w * 0.8),
                        SizedBox(height: h * 0.03),
                        bar(w * 0.55),
                      ],
                    ),
                  ),
                ],
              ),
              Positioned(
                left: spot.dx * w - 4,
                top: spot.dy * h - 4,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: const Color(0xFF111111),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
