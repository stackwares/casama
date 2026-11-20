import 'dart:async';

import 'package:casama_sdk/casama_sdk.dart'
    show
        Canvas,
        CanvasBackgroundKindEnum,
        CanvasEntry,
        CanvasEntryCountEnum,
        CanvasEntryTemplateEnum,
        CanvasLook,
        CanvasLookAlignEnum,
        CanvasLookFontEnum,
        CanvasLookInkEnum;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart' hide Canvas;

import '../../core/media_cache.dart';
import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../theme/app_colors.dart';
import '../../ui/bot_avatar.dart';

/// Draws a bot's canvas in Flutter the way the Canvas widget draws it (docs/BOT-WIDGET-PLAN.md
/// §6.3): for the chat's preview card and Settings → Widgets. The server already cut the text and
/// chose the text colour (`look.ink`); this only draws.

/// The Home Screen sizes the app draws: iPhone's small and medium widgets.
enum CanvasSize {
  small(Size(158, 158)),
  medium(Size(338, 158));

  const CanvasSize(this.size);
  final Size size;
}

/// The near-black text and the app's dark surface (D-380).
const canvasDarkInk = Color(0xFF1C1C1E);
const _darkSurface = Color(0xFF1C1C1E);

/// The text colour the server chose; `auto` follows light and dark mode.
Color canvasInk(CanvasLookInkEnum ink, Brightness brightness) => switch (ink) {
  CanvasLookInkEnum.light => Colors.white,
  CanvasLookInkEnum.dark => canvasDarkInk,
  CanvasLookInkEnum.auto => brightness == Brightness.dark ? Colors.white : canvasDarkInk,
};

/// `#rrggbb` as a colour; null when it isn't one.
Color? canvasColor(String? hex) {
  if (hex == null) return null;
  final m = RegExp(r'^#([0-9a-fA-F]{6})$').firstMatch(hex.trim());
  return m == null ? null : Color(0xFF000000 | int.parse(m[1]!, radix: 16));
}

/// The system's own font designs (§6.2); `rounded` keeps the default where there is no rounded one.
TextStyle canvasFont(CanvasLookFontEnum font) => switch (font) {
  CanvasLookFontEnum.serif => const TextStyle(fontFamily: 'Georgia', fontFamilyFallback: ['New York', 'Noto Serif', 'serif', 'Times New Roman']),
  CanvasLookFontEnum.mono => const TextStyle(fontFamily: 'Menlo', fontFamilyFallback: ['SF Mono', 'Roboto Mono', 'monospace', 'Consolas', 'Courier New']),
  CanvasLookFontEnum.rounded => const TextStyle(fontFamilyFallback: ['SF Pro Rounded', '.SF UI Rounded']),
  CanvasLookFontEnum.plain => const TextStyle(),
};

/// Icon names a bot may give (`look.icon`); anything else that isn't an emoji is skipped.
const canvasIcons = <String, IconData>{
  'checklist': LucideIcons.listChecks,
  'list': LucideIcons.listChecks,
  'check': LucideIcons.check,
  'heart': LucideIcons.heart,
  'star': LucideIcons.star,
  'sun': LucideIcons.sun,
  'moon': LucideIcons.moon,
  'book': LucideIcons.bookOpen,
  'bible': LucideIcons.bookOpen,
  'quote': LucideIcons.quote,
  'flame': LucideIcons.flame,
  'fire': LucideIcons.flame,
  'trophy': LucideIcons.trophy,
  'calendar': LucideIcons.calendar,
  'clock': LucideIcons.clock,
  'plane': LucideIcons.plane,
  'music': LucideIcons.music,
  'coffee': LucideIcons.coffee,
  'leaf': LucideIcons.leaf,
  'cloud': LucideIcons.cloud,
  'weather': LucideIcons.cloudSun,
  'umbrella': LucideIcons.umbrella,
  'bell': LucideIcons.bell,
  'target': LucideIcons.target,
  'dumbbell': LucideIcons.dumbbell,
  'gift': LucideIcons.gift,
  'home': LucideIcons.house,
  'pin': LucideIcons.mapPin,
  'sparkles': LucideIcons.sparkles,
  'steps': LucideIcons.footprints,
  'water': LucideIcons.droplet,
  'pill': LucideIcons.pill,
  'smile': LucideIcons.smile,
};

/// An icon name is plain lower-case letters, digits, `-` and `_`; anything else is an emoji.
bool _isIconName(String icon) => RegExp(r'^[a-z0-9_\-]+$').hasMatch(icon);

/// `look.icon` drawn: an emoji as text, a known name as an icon, nothing for an unknown name.
Widget? canvasIcon(String? icon, {required Color color, double size = 14}) {
  final i = icon?.trim() ?? '';
  if (i.isEmpty) return null;
  if (!_isIconName(i)) return Text(i, style: TextStyle(fontSize: size, height: 1.1));
  final data = canvasIcons[i];
  return data == null ? null : Icon(data, size: size, color: color);
}

/// A number as a widget shows it: whole numbers without a point, others with one decimal.
String canvasNumber(num v) => v == v.roundToDouble() ? '${v.round()}' : v.toStringAsFixed(1);

/// One canvas, drawn at [size]: its `entries[0]` (the one showing now). A canvas with no entries
/// (a private key) shows its name and bot only; [locked] shows the name only when the canvas hides
/// on a locked phone.
class CanvasView extends ConsumerWidget {
  const CanvasView({super.key, required this.canvas, this.size = CanvasSize.small, this.locked = false, this.now});
  final Canvas canvas;
  final CanvasSize size;
  final bool locked;

  /// The clock, for tests.
  final DateTime Function()? now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brightness = Theme.of(context).brightness;
    final entry = canvas.entries.firstOrNull;
    final look = entry?.look;
    final ink = canvasInk(look?.ink ?? CanvasLookInkEnum.auto, brightness);
    final medium = size == CanvasSize.medium;
    final namesOnly = entry == null || (locked && canvas.hideWhenLocked);
    final base = canvasFont(look?.font ?? CanvasLookFontEnum.plain).copyWith(color: ink, height: 1.25);
    final center = look?.align == CanvasLookAlignEnum.center;

    // The picture behind it: the background's, or the entry's own for the picture template.
    final pictureHash = entry == null
        ? null
        : (entry.template == CanvasEntryTemplateEnum.picture
              ? entry.picture ?? look?.background.picture
              : (look!.background.kind == CanvasBackgroundKindEnum.picture ? look.background.picture : null));
    final hasPicture = pictureHash != null && pictureHash.isNotEmpty;

    final body = namesOnly
        ? _NamesOnly(canvas: canvas, ink: ink, medium: medium)
        : _EntryBody(canvas: canvas, entry: entry, look: look!, ink: ink, medium: medium, center: center, now: now ?? DateTime.now, overPicture: hasPicture);

    return Semantics(
      label: '${canvas.name} · ${canvas.bot}',
      child: MediaQuery.withNoTextScaling(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: SizedBox.fromSize(
            size: size.size,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _Background(canvasId: canvas.id, look: look, picture: hasPicture ? pictureHash : null, ink: ink),
                // A soft shade under light text on a picture, so it reads on any photo.
                if (hasPicture && ink == Colors.white)
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0x33000000), Color(0x8C000000)]),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: DefaultTextStyle(style: base.copyWith(fontSize: 13), textAlign: center ? TextAlign.center : TextAlign.start, child: body),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Background extends ConsumerWidget {
  const _Background({required this.canvasId, required this.look, required this.picture, required this.ink});
  final String canvasId;
  final CanvasLook? look;
  final String? picture;
  final Color ink;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auto = context.isDark ? _darkSurface : Colors.white;
    final bg = look?.background;
    final plain = switch (bg?.kind) {
      CanvasBackgroundKindEnum.color => ColoredBox(color: canvasColor(bg!.color) ?? auto),
      CanvasBackgroundKindEnum.gradient => DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [canvasColor(bg!.from) ?? auto, canvasColor(bg.to) ?? canvasColor(bg.from) ?? auto],
          ),
        ),
      ),
      _ => ColoredBox(color: auto),
    };
    final hash = picture;
    if (hash == null) return plain;
    // While it loads (or when it can't), a plain colour the text still reads on.
    final waiting = ColoredBox(color: ink == Colors.white ? const Color(0xFF3A3A3C) : const Color(0xFFE5E5EA));
    final backend = ref.watch(backendProvider);
    return Image(
      image: cachedNetworkImage(backend.canvasPictureUrl(canvasId, hash), headers: backend.authHeaders),
      fit: BoxFit.cover,
      gaplessPlayback: true,
      frameBuilder: (context, child, frame, sync) => sync || frame != null ? child : waiting,
      errorBuilder: (_, _, _) => waiting,
    );
  }
}

/// The bot's name and mark, small, in the corner of Home Screen sizes.
class _BotMark extends StatelessWidget {
  const _BotMark({required this.canvas, required this.ink});
  final Canvas canvas;
  final Color ink;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    spacing: 4,
    children: [
      BotAvatar(name: canvas.bot, avatar: canvas.botAvatar.isEmpty ? null : canvas.botAvatar, size: 14),
      Flexible(
        child: Text(
          canvas.bot,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: ink.withValues(alpha: 0.75)),
        ),
      ),
    ],
  );
}

/// A private key's canvas, or one hidden on a locked phone: the name and the bot.
class _NamesOnly extends StatelessWidget {
  const _NamesOnly({required this.canvas, required this.ink, required this.medium});
  final Canvas canvas;
  final Color ink;
  final bool medium;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(LucideIcons.layoutGrid, size: 16, color: ink.withValues(alpha: 0.7)),
      const Spacer(),
      Text(
        canvas.name,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: medium ? 18 : 16, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 6),
      _BotMark(canvas: canvas, ink: ink),
    ],
  );
}

class _EntryBody extends StatelessWidget {
  const _EntryBody({
    required this.canvas,
    required this.entry,
    required this.look,
    required this.ink,
    required this.medium,
    required this.center,
    required this.now,
    required this.overPicture,
  });
  final Canvas canvas;
  final CanvasEntry entry;
  final CanvasLook look;
  final Color ink;
  final bool medium;
  final bool center;
  final DateTime Function() now;
  final bool overPicture;

  @override
  Widget build(BuildContext context) {
    final accent = canvasColor(look.accent) ?? context.colorScheme.primary;
    final icon = canvasIcon(look.icon, color: ink, size: 15);
    final title = entry.title?.trim() ?? '';
    final footer = entry.footer?.trim() ?? '';
    final cross = center ? CrossAxisAlignment.center : CrossAxisAlignment.start;
    final header = (icon == null && title.isEmpty) || entry.template == CanvasEntryTemplateEnum.picture && title.isEmpty
        ? null
        : Row(
            mainAxisAlignment: center ? MainAxisAlignment.center : MainAxisAlignment.start,
            spacing: 6,
            children: [
              ?icon,
              if (title.isNotEmpty)
                Flexible(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                ),
            ],
          );
    final main = switch (entry.template) {
      CanvasEntryTemplateEnum.text => _textBody(),
      CanvasEntryTemplateEnum.countdown => _CountdownBody(entry: entry, medium: medium, center: center, now: now),
      CanvasEntryTemplateEnum.number => _numberBody(context, accent),
      CanvasEntryTemplateEnum.list => _listBody(),
      CanvasEntryTemplateEnum.picture => _pictureBody(),
    };
    return Column(
      crossAxisAlignment: cross,
      children: [
        if (header != null) ...[header, const SizedBox(height: 6)],
        Expanded(child: main),
        const SizedBox(height: 6),
        Row(
          spacing: 6,
          children: [
            Expanded(
              child: Text(
                footer,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, color: ink.withValues(alpha: 0.75)),
              ),
            ),
            _BotMark(canvas: canvas, ink: ink),
          ],
        ),
      ],
    );
  }

  Widget _textBody() => Align(
    alignment: center ? Alignment.center : Alignment.centerLeft,
    child: Text(
      entry.text ?? '',
      maxLines: medium ? 4 : 5,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(fontSize: medium ? 17 : 15, fontWeight: FontWeight.w600),
    ),
  );

  Widget _numberBody(BuildContext context, Color accent) {
    final value = entry.value;
    final of = entry.of_;
    final unit = entry.unit?.trim() ?? '';
    final shown = value == null ? '–' : canvasNumber(value);
    final figure = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          shown,
          maxLines: 1,
          style: TextStyle(fontSize: of != null ? 20 : 34, fontWeight: FontWeight.w800, height: 1.05),
        ),
        if (unit.isNotEmpty)
          Text(
            unit,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 10, color: ink.withValues(alpha: 0.75)),
          ),
      ],
    );
    if (of == null || of <= 0) {
      return Align(
        alignment: center ? Alignment.center : Alignment.centerLeft,
        child: FittedBox(fit: BoxFit.scaleDown, child: figure),
      );
    }
    final share = ((value ?? 0) / of).clamp(0.0, 1.0).toDouble();
    final ring = SizedBox.square(
      dimension: 72,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(
            child: CircularProgressIndicator(
              value: share,
              strokeWidth: 7,
              color: accent,
              backgroundColor: ink.withValues(alpha: 0.18),
              strokeCap: StrokeCap.round,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: FittedBox(fit: BoxFit.scaleDown, child: figure),
          ),
        ],
      ),
    );
    if (!medium) {
      return Center(
        child: FittedBox(fit: BoxFit.scaleDown, child: ring),
      );
    }
    return Row(
      spacing: 14,
      children: [
        FittedBox(fit: BoxFit.scaleDown, child: ring),
        Expanded(
          child: Text(
            '${canvasNumber(value ?? 0)} / ${canvasNumber(of)}${unit.isEmpty ? '' : ' $unit'}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: ink.withValues(alpha: 0.9)),
          ),
        ),
      ],
    );
  }

  Widget _listBody() {
    final rows = entry.items.take(medium ? 4 : 3).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 3,
      children: [
        for (final item in rows)
          Row(
            spacing: 6,
            children: [
              Icon(item.done ? LucideIcons.circleCheck : LucideIcons.circle, size: 13, color: ink.withValues(alpha: item.done ? 0.6 : 0.9)),
              Expanded(
                child: Text(
                  item.text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    decoration: item.done ? TextDecoration.lineThrough : null,
                    decorationColor: ink,
                    color: item.done ? ink.withValues(alpha: 0.6) : ink,
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _pictureBody() {
    final caption = entry.text?.trim() ?? '';
    return Align(
      alignment: center ? Alignment.bottomCenter : Alignment.bottomLeft,
      child: caption.isEmpty
          ? const SizedBox.shrink()
          : Text(
              caption,
              maxLines: medium ? 3 : 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
    );
  }
}

/// The time to (or since) `target`: days as words, under a day a clock that ticks by itself, as
/// the system's timer does on the widget.
class _CountdownBody extends StatefulWidget {
  const _CountdownBody({required this.entry, required this.medium, required this.center, required this.now});
  final CanvasEntry entry;
  final bool medium;
  final bool center;
  final DateTime Function() now;

  @override
  State<_CountdownBody> createState() => _CountdownBodyState();
}

class _CountdownBodyState extends State<_CountdownBody> {
  Timer? _tick;

  Duration _left() {
    final target = widget.entry.target;
    if (target == null) return Duration.zero;
    final d = widget.entry.count == CanvasEntryCountEnum.up ? widget.now().difference(target) : target.difference(widget.now());
    return d.isNegative ? Duration.zero : d;
  }

  void _schedule() {
    _tick?.cancel();
    _tick = null;
    if (_left().inDays < 1 && widget.entry.target != null) {
      _tick = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _schedule();
  }

  @override
  void didUpdateWidget(covariant _CountdownBody old) {
    super.didUpdateWidget(old);
    if (old.entry.target != widget.entry.target) _schedule();
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final left = _left();
    final l10n = context.l10n;
    final String big;
    final String? unit;
    if (left.inDays >= 1) {
      big = '${left.inDays}';
      unit = l10n.canvasDaysUnit(left.inDays);
    } else {
      String two(int n) => n.toString().padLeft(2, '0');
      big = '${left.inHours}:${two(left.inMinutes % 60)}:${two(left.inSeconds % 60)}';
      unit = null;
    }
    final text = widget.entry.text?.trim() ?? '';
    return Column(
      crossAxisAlignment: widget.center ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            spacing: 5,
            children: [
              Text(
                big,
                style: TextStyle(fontSize: widget.medium ? 40 : 36, fontWeight: FontWeight.w800, height: 1, fontFeatures: const [FontFeature.tabularFigures()]),
              ),
              if (unit != null) Text(unit, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        if (widget.medium && text.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
        ],
      ],
    );
  }
}

/// The Lock Screen's rectangle (§6.3), in one line: the icon and `short`, light on dark the way the
/// Lock Screen tints it. A canvas hidden on a locked phone, or with no entries, shows its name.
class CanvasLockLine extends StatelessWidget {
  const CanvasLockLine({super.key, required this.canvas});
  final Canvas canvas;

  @override
  Widget build(BuildContext context) {
    final entry = canvas.entries.firstOrNull;
    final text = entry == null || canvas.hideWhenLocked ? canvas.name : entry.short;
    final icon = canvasIcon(entry?.look.icon, color: Colors.white, size: 13);
    return MediaQuery.withNoTextScaling(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 338),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(color: const Color(0xFF2C2C2E), borderRadius: BorderRadius.circular(14)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 6,
          children: [
            ?icon,
            Flexible(
              child: Text(
                text,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white, height: 1.25),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
