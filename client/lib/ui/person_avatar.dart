import 'package:flutter/material.dart';

import '../core/media_cache.dart';

/// A person in a circle: their profile photo (D-202) when they have one, else the first letter
/// of [label] on an accent tint. Falls back to the letter while the photo loads or if it can't.
class PersonAvatar extends StatelessWidget {
  const PersonAvatar({
    super.key,
    required this.label,
    this.photoUrl,
    this.size = 36,
  });

  /// Their name or email; the first letter shows when there's no photo.
  final String label;
  final String? photoUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final initial = Center(
      child: Text(
        label.trim().isEmpty
            ? '?'
            : label.trim().characters.first.toUpperCase(),
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: scheme.primary,
          fontWeight: FontWeight.w800,
          fontSize: size * 0.42,
          height: 1,
        ),
      ),
    );
    final url = photoUrl;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.16),
        shape: BoxShape.circle,
      ),
      clipBehavior: Clip.antiAlias,
      child: url == null
          ? initial
          : Image(
              image: cachedNetworkImage(url),
              key: ValueKey(url),
              fit: BoxFit.cover,
              width: size,
              height: size,
              gaplessPlayback: true,
              excludeFromSemantics: true,
              frameBuilder: (context, child, frame, sync) => sync
                  ? child
                  : AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: frame == null ? initial : child,
                    ),
              errorBuilder: (_, _, _) => initial,
            ),
    );
  }
}
