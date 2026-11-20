import 'dart:async';

import 'package:casama_sdk/casama_sdk.dart' show Canvas, CanvasPreviewEventPayload, CanvasPreviewEventPayloadStateEnum, CanvasStatusEnum;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart' hide Canvas;

import '../../core/analytics.dart';
import '../../core/haptics.dart';
import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../theme/app_colors.dart';
import '../../ui/action_buttons.dart';
import '../../ui/glow_button.dart';
import '../chat/widgets/chat_look.dart';
import 'canvas_sync.dart';
import 'canvas_view.dart';
import 'widgets_screen.dart';

/// Where the preview card stands: what the event said, then what the person did.
enum _Phase { ask, notPlaced, shown, allowed, declined, gone, added }

/// The chat's card for a `canvas.preview` run event (docs/BOT-WIDGET-PLAN.md §8.5): the canvas
/// drawn as the widget draws it, and buttons by its state. Waiting for the person's yes: **Show on
/// my widgets** and **Not now**. Showing but no Canvas widget placed: **Add to Home screen** on
/// Android, the steps elsewhere. Showing: no buttons.
class CanvasPreviewCard extends ConsumerStatefulWidget {
  const CanvasPreviewCard({super.key, required this.preview, this.now});
  final CanvasPreviewEventPayload preview;

  /// The clock, for tests.
  final DateTime Function()? now;

  @override
  ConsumerState<CanvasPreviewCard> createState() => _CanvasPreviewCardState();
}

class _CanvasPreviewCardState extends ConsumerState<CanvasPreviewCard> {
  late _Phase _phase = switch (widget.preview.state) {
    CanvasPreviewEventPayloadStateEnum.waiting => _Phase.ask,
    CanvasPreviewEventPayloadStateEnum.notPlaced => _Phase.notPlaced,
    CanvasPreviewEventPayloadStateEnum.shown => _Phase.shown,
  };
  late Canvas _canvas = widget.preview.canvas;
  var _busy = false;

  @override
  void initState() {
    super.initState();
    unawaited(_catchUp());
  }

  /// The card may be old (a reloaded chat): what the canvas is now. Answered elsewhere, it shows
  /// as answered; cleared, it says so.
  Future<void> _catchUp() async {
    final orgId = widget.preview.canvas.orgId;
    try {
      final list = await ref.read(backendProvider).canvases(orgId);
      if (!mounted || list == null || list.version.isEmpty) return;
      final now = list.items.where((c) => c.id == widget.preview.canvasId).firstOrNull;
      setState(() {
        if (now == null) {
          if (_phase != _Phase.declined) _phase = _Phase.gone;
          return;
        }
        if (now.version >= _canvas.version) _canvas = now;
        if (_phase == _Phase.ask && now.status != CanvasStatusEnum.waiting) _phase = _Phase.shown;
      });
    } catch (_) {
      // Offline: the card as the event left it.
    }
  }

  Future<void> _allow() async {
    HapticsHelper.light();
    setState(() => _busy = true);
    final ok = await runGuarded(context, () async {
      await ref.read(backendProvider).setCanvasGrant(widget.preview.botId, true);
      return true;
    });
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (ok == true) _phase = _Phase.allowed;
    });
    if (ok == true) {
      Analytics.log('canvas_allowed', {'choice': 'allow'});
      canvasesChanged(ref);
    }
  }

  Future<void> _notNow() async {
    setState(() => _busy = true);
    final ok = await runGuarded(context, () async {
      await ref.read(backendProvider).clearCanvas(widget.preview.canvasId);
      return true;
    });
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (ok == true) _phase = _Phase.declined;
    });
    if (ok == true) {
      Analytics.log('canvas_allowed', {'choice': 'not_now'});
      canvasesChanged(ref);
    }
  }

  Future<void> _add() async {
    HapticsHelper.light();
    final ok = await ref.read(widgetPinnerProvider).pin(WidgetKind.canvas);
    if (!mounted) return;
    if (ok) {
      setState(() => _phase = _Phase.added);
    } else {
      showMessage(context, context.l10n.widgetsPinUnsupported);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final bot = _canvas.bot;
    // Not now, or cleared since: one quiet line.
    if (_phase == _Phase.declined || _phase == _Phase.gone) {
      return _Line(
        key: const Key('canvasPreview'),
        text: _phase == _Phase.declined ? l10n.canvasNotShown(bot) : l10n.canvasGone,
        color: context.colorScheme.onSurfaceVariant,
        icon: LucideIcons.circleMinus,
      );
    }
    final scheme = context.colorScheme;
    final platform = kIsWeb ? null : defaultTargetPlatform;
    final android = platform == TargetPlatform.android;
    final canPin = android && (ref.watch(pinWidgetSupportedProvider).value ?? false);
    final footer = switch (_phase) {
      _Phase.ask => ActionButtons(
        actions: [
          OutlinedButton(key: const Key('canvasNotNow'), onPressed: _busy ? null : _notNow, child: Text(l10n.notNow)),
          GlowButton.icon(
            key: const Key('canvasShow'),
            onPressed: _busy ? null : _allow,
            icon: const Icon(LucideIcons.check, size: 18),
            label: Text(l10n.canvasShow),
          ),
        ],
      ),
      _Phase.notPlaced when canPin => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 10,
        children: [
          Text(l10n.canvasNotPlaced, style: context.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
          FilledButton.tonal(key: const Key('canvasAdd'), onPressed: _add, child: Text(l10n.widgetsAddToHome)),
        ],
      ),
      _Phase.notPlaced => Text(key: const Key('canvasHowTo'), switch (platform) {
        TargetPlatform.iOS => l10n.canvasHowToIos,
        TargetPlatform.macOS => l10n.canvasHowToMac,
        TargetPlatform.android => l10n.widgetsPinUnsupported,
        _ => l10n.canvasHowToElsewhere,
      }, style: context.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant, height: 1.4)),
      _Phase.allowed => _Line(text: l10n.canvasShowing, color: colors.positive, icon: LucideIcons.circleCheck),
      _Phase.added => _Line(text: l10n.canvasAdded, color: colors.positive, icon: LucideIcons.circleCheck),
      _ => null,
    };
    return Container(
      key: const Key('canvasPreview'),
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
                child: Icon(LucideIcons.layoutGrid, size: 17, color: scheme.primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.canvasCardLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            _phase == _Phase.ask ? l10n.canvasPreviewAsk(bot) : l10n.canvasPreviewSet(bot),
            style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, height: 1.3),
          ),
          if (_phase == _Phase.ask)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(l10n.canvasPreviewAskHelp(bot), style: context.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant, height: 1.4)),
            ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerLeft,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: CanvasView(canvas: _canvas, size: CanvasSize.medium, now: widget.now),
            ),
          ),
          const SizedBox(height: 10),
          Text(l10n.canvasLockScreen, style: context.textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant)),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: CanvasLockLine(canvas: _canvas),
          ),
          if (footer != null) ...[const SizedBox(height: 14), footer],
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({super.key, required this.text, required this.color, required this.icon});
  final String text;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4),
    child: Row(
      spacing: 6,
      children: [
        Icon(icon, size: 18, color: color),
        Flexible(
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: context.textTheme.labelLarge?.copyWith(color: color, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
}
