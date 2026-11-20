import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';
import 'package:casama_sdk/casama_sdk.dart';

import '../core/media_cache.dart';
import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';
import 'mascot.dart';
import 'motion.dart';

/// Gradients bots draw from, picked by name so a bot keeps its color everywhere.
const _palettes = <List<Color>>[
  [Color(0xFF14B8A6), Color(0xFF0F766E)],
  [Color(0xFF6366F1), Color(0xFF4338CA)],
  [Color(0xFFF59E0B), Color(0xFFD97706)],
  [Color(0xFFEC4899), Color(0xFFBE185D)],
  [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
  [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
  [Color(0xFF10B981), Color(0xFF047857)],
  [Color(0xFFF97316), Color(0xFFC2410C)],
];

List<Color> botPalette(String name) {
  var h = 0;
  for (final c in name.toLowerCase().codeUnits) {
    h = (h * 31 + c) & 0x7fffffff;
  }
  return _palettes[h % _palettes.length];
}

/// A bot's own picture, as `bots.avatar_url` names it: `image:<id>:<rrggbb><rrggbb>`, with the two
/// colours the server took from it (docs/BOT-PICTURES-PLAN.md §5.1; the same rules as
/// packages/domain/src/bot-avatar.ts and its test vectors).
class BotPictureRef {
  const BotPictureRef(this.id, this.colors);
  final String id;
  final List<Color> colors;

  static final _value = RegExp(
    r'^image:([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}):([0-9a-f]{6})([0-9a-f]{6})$',
  );

  /// The picture [avatar] names, or null for a mascot, initials or anything unknown.
  static BotPictureRef? parse(String? avatar) {
    if (avatar == null) return null;
    final m = _value.firstMatch(avatar);
    if (m == null) return null;
    Color c(String hex) => Color(0xFF000000 | int.parse(hex, radix: 16));
    return BotPictureRef(m.group(1)!, [c(m.group(2)!), c(m.group(3)!)]);
  }
}

/// A bot's colors as people see them: its picture's or its mascot's when it has one, otherwise its
/// initials gradient.
List<Color> botColors(String name, String? avatar) =>
    BotPictureRef.parse(avatar)?.colors ?? Mascot.fromAvatar(avatar)?.colors ?? botPalette(name);

/// A bot's initials, as its avatar shows them.
String botInitials(String name) => _initials(name);

String _initials(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((p) => p.isNotEmpty)
      .toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first.characters.first.toUpperCase();
  return (parts.first.characters.first + parts[1].characters.first)
      .toUpperCase();
}

/// A bot's mark: its own picture (in the rounded square), its chosen mascot (transparent, no tile),
/// or a rounded square in its gradient with its initials; plus a status dot that pulses while it
/// works.
class BotAvatar extends StatelessWidget {
  const BotAvatar({
    super.key,
    required this.name,
    this.avatar,
    this.size = 40,
    this.status,
    this.ringColor,
    this.animate,
    this.preview,
  });

  /// Where bot pictures are served (`Backend.botImageUrl`), set once the backend exists. Unset (in
  /// widget tests), a picture shows as initials on its own colours.
  static String Function(String imageId, {bool small})? imageUrl;

  /// The corner radius of a bot's tile at [size]: the cropper's frame uses the same shape.
  static double radiusFor(double size) => size * 0.32;

  final String name;

  /// The bot's `avatar_url`: `mascot:<name>` picks one of the cloud bots, `image:<id>:<colours>`
  /// its own picture.
  final String? avatar;

  /// A picture just cropped, shown at once while it uploads (and after, so it never flickers).
  final Uint8List? preview;
  final double size;
  final BotStatusEnum? status;

  /// Whether a mascot plays its animation. Defaults to large avatars only, so lists stay calm.
  final bool? animate;

  /// The surface behind the avatar, for the gap around the status dot.
  final Color? ringColor;

  @override
  Widget build(BuildContext context) {
    final picture = BotPictureRef.parse(avatar);
    final colors = picture?.colors ?? botPalette(name);
    final radius = radiusFor(size);
    final dotColor = switch (status) {
      BotStatusEnum.working => context.appColors.working,
      BotStatusEnum.waiting => context.appColors.waiting,
      _ => null,
    };
    final dot = size * 0.3;
    Widget? statusDot;
    if (dotColor != null) {
      statusDot = Container(
        width: dot,
        height: dot,
        decoration: BoxDecoration(
          color: dotColor,
          shape: BoxShape.circle,
          border: Border.all(
            color: ringColor ?? context.colorScheme.surface,
            width: size * 0.06,
          ),
        ),
      );
      if (status == BotStatusEnum.working) statusDot = Pulse(child: statusDot);
    }
    final mascot = Mascot.fromAvatar(avatar);
    final initials = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: colors),
      ),
      alignment: Alignment.center,
      child: ExcludeSemantics(
        child: Text(
          _initials(name),
          style: (Theme.of(context).textTheme.headlineSmall ?? const TextStyle()).copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: size * (name.trim().contains(' ') ? 0.36 : 0.44),
            height: 1,
            letterSpacing: -0.5,
          ),
        ),
      ),
    );
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (preview != null || picture != null)
            Semantics(
              image: true,
              label: name,
              child: _BotPicture(
                picture: picture,
                preview: preview,
                size: size,
                radius: radius,
                placeholder: initials,
              ),
            )
          else if (mascot != null)
            MascotImage(
              mascot,
              size: size,
              animate: animate ?? size >= 52,
              semanticLabel: name,
            )
          else
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(radius),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: colors,
                ),
                boxShadow: [
                  if (size >= 56)
                    BoxShadow(
                      color: colors.last.withValues(
                        alpha: context.isDark ? 0.5 : 0.3,
                      ),
                      blurRadius: size * 0.3,
                      offset: Offset(0, size * 0.1),
                    ),
                ],
              ),
              alignment: Alignment.center,
              child: ExcludeSemantics(
                child: Text(
                  _initials(name),
                  style: (Theme.of(context).textTheme.headlineSmall ?? const TextStyle()).copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: size * (name.trim().contains(' ') ? 0.36 : 0.44),
                    height: 1,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ),
          if (statusDot != null)
            Positioned(
              right: -size * 0.06,
              bottom: -size * 0.06,
              child: statusDot,
            ),
        ],
      ),
    );
  }
}

/// A bot's own picture in its rounded square. Until it has loaded (only the first time: pictures
/// never change under the same id, and they're kept on the device), the initials show on the
/// picture's own colours, then the picture fades in over them. A picture with see-through parts
/// (a logo) shows without a tile once loaded, like a mascot.
class _BotPicture extends StatelessWidget {
  const _BotPicture({
    required this.picture,
    required this.preview,
    required this.size,
    required this.radius,
    required this.placeholder,
  });

  final BotPictureRef? picture;
  final Uint8List? preview;
  final double size;
  final double radius;
  final Widget placeholder;

  @override
  Widget build(BuildContext context) {
    final ImageProvider? image;
    final bytes = preview;
    final url = picture == null ? null : BotAvatar.imageUrl?.call(picture!.id, small: size <= 64);
    if (bytes != null) {
      image = MemoryImage(bytes);
    } else if (url != null) {
      image = cachedNetworkImage(url);
    } else {
      image = null;
    }
    if (image == null) return placeholder;
    final px = (size * MediaQuery.devicePixelRatioOf(context)).ceil();
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: size,
        height: size,
        child: Image(
          image: ResizeImage.resizeIfNeeded(px, px, image),
          width: size,
          height: size,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          filterQuality: FilterQuality.medium,
          excludeFromSemantics: true,
          frameBuilder: (context, child, frame, sync) {
            if (sync) return child;
            return Stack(
              fit: StackFit.expand,
              children: [
                AnimatedOpacity(
                  opacity: frame == null ? 1 : 0,
                  duration: AppMotion.of(context, AppMotion.fast),
                  child: placeholder,
                ),
                AnimatedOpacity(
                  opacity: frame == null ? 0 : 1,
                  duration: AppMotion.of(context, AppMotion.fast),
                  curve: AppMotion.curve,
                  child: child,
                ),
              ],
            );
          },
          errorBuilder: (_, _, _) => placeholder,
        ),
      ),
    );
  }
}
