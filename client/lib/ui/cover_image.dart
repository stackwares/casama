import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// A picture in memory, decoded at the size it shows with [BoxFit.cover] in a [width] x [height]
/// box of physical pixels, never larger than the original. A 168 x 126 thumbnail of a
/// 12-megapixel photo then holds about 0.5 MB of pixels instead of 48 MB, and decodes faster.
@immutable
class CoverMemoryImage extends ImageProvider<CoverMemoryImage> {
  const CoverMemoryImage(this.bytes, {required this.width, required this.height});

  /// For a box of [size] logical pixels on a screen of [pixelRatio].
  CoverMemoryImage.sized(this.bytes, Size size, double pixelRatio) : width = math.max(1, (size.width * pixelRatio).ceil()), height = math.max(1, (size.height * pixelRatio).ceil());

  final Uint8List bytes;
  final int width;
  final int height;

  @override
  Future<CoverMemoryImage> obtainKey(ImageConfiguration configuration) => SynchronousFuture<CoverMemoryImage>(this);

  @override
  ImageStreamCompleter loadImage(CoverMemoryImage key, ImageDecoderCallback decode) => MultiFrameImageStreamCompleter(codec: _decode(decode), scale: 1);

  Future<ui.Codec> _decode(ImageDecoderCallback decode) async {
    final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    return decode(buffer, getTargetSize: (w, h) => coverTargetSize(w, h, width, height));
  }

  @override
  bool operator ==(Object other) => other is CoverMemoryImage && identical(other.bytes, bytes) && other.width == width && other.height == height;

  @override
  int get hashCode => Object.hash(identityHashCode(bytes), width, height);
}

/// The decode size that covers a [width] x [height] box from a [w] x [h] picture, keeping its
/// aspect ratio and never scaling it up.
@visibleForTesting
ui.TargetImageSize coverTargetSize(int w, int h, int width, int height) {
  final scale = math.max(width / w, height / h);
  if (scale >= 1) return ui.TargetImageSize(width: w, height: h);
  // Rounded up, less a hair of floating-point error (3000 x 0.084 is 252.00000000000003).
  int up(double v) => math.max(1, (v - 1e-6).ceil());
  return ui.TargetImageSize(width: up(w * scale), height: up(h * scale));
}
