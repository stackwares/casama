import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../theme/app_tokens.dart';
import '../../../core/media_cache.dart';
import '../../../ui/effects.dart';
import '../../../ui/skeleton.dart';
import 'media_kind.dart';

/// A picture in a chat at its own shape (see [chatImageBox]): a photo, a GIF or an SVG drawing,
/// from bytes or a web address. While it loads, a rounded block in the theme's skeleton tone holds
/// its place, sized from [width] and [height] when they're known so nothing jumps. GIFs hold
/// still on their first frame with a play badge when decorative motion is off.
class ChatPicture extends StatefulWidget {
  const ChatPicture({
    super.key,
    required this.kind,
    this.bytes,
    this.url,
    this.headers,
    this.width,
    this.height,
    this.onTap,
    this.tapKey,
    this.semanticLabel,
    this.fallback,
    this.fit,
  });

  final MediaKind kind;

  /// The picture's bytes, or null while they load (unless [url] is given).
  final Uint8List? bytes;
  final String? url;
  final Map<String, String>? headers;

  /// Its own size in pixels, when the chat knows it.
  final int? width;
  final int? height;
  final VoidCallback? onTap;
  final Key? tapKey;
  final String? semanticLabel;

  /// Shown instead when the picture can't be read.
  final WidgetBuilder? fallback;

  /// A fixed box to fill (grids); null keeps the picture's own shape.
  final Size? fit;

  @override
  State<ChatPicture> createState() => _ChatPictureState();
}

class _ChatPictureState extends State<ChatPicture> {
  Size? _natural;
  ui.Image? _firstFrame;
  var _failed = false;
  var _playing = false;
  Object? _source;

  @override
  void initState() {
    super.initState();
    _natural = widget.width != null && widget.height != null
        ? Size(widget.width!.toDouble(), widget.height!.toDouble())
        : null;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _inspect();
  }

  @override
  void didUpdateWidget(ChatPicture old) {
    super.didUpdateWidget(old);
    if (old.bytes != widget.bytes || old.url != widget.url) _inspect();
  }

  @override
  void dispose() {
    _firstFrame?.dispose();
    super.dispose();
  }

  bool get _still =>
      widget.kind == MediaKind.gif && !_playing && !Effects.decorative(context);

  /// Reads the picture's size (and a GIF's first frame) once per source.
  void _inspect() {
    final source = widget.bytes ?? widget.url;
    if (source == null || identical(source, _source)) return;
    _source = source;
    final bytes = widget.bytes;
    if (widget.kind == MediaKind.svg) {
      if (bytes != null) unawaited(_inspectSvg(bytes));
      return;
    }
    if (bytes != null) {
      unawaited(_inspectRaster(bytes));
    } else if (_natural == null && widget.url != null) {
      final stream = cachedNetworkImage(
        widget.url!,
        headers: widget.headers,
      ).resolve(ImageConfiguration.empty);
      late final ImageStreamListener listener;
      listener = ImageStreamListener(
        (info, _) {
          stream.removeListener(listener);
          if (mounted) {
            setState(
              () => _natural = Size(
                info.image.width.toDouble(),
                info.image.height.toDouble(),
              ),
            );
          }
        },
        onError: (_, _) {
          stream.removeListener(listener);
          if (mounted) setState(() => _failed = true);
        },
      );
      stream.addListener(listener);
    }
  }

  Future<void> _inspectRaster(Uint8List bytes) async {
    // The web engine has no ImageDescriptor.encoded: decode once instead, which is what the
    // picture does next anyway. Without this every picture in a web chat showed as broken.
    if (kIsWeb) {
      try {
        final codec = await ui.instantiateImageCodec(bytes);
        final frame = await codec.getNextFrame();
        codec.dispose();
        final image = frame.image;
        final size = Size(image.width.toDouble(), image.height.toDouble());
        final still = widget.kind == MediaKind.gif && mounted && _still;
        if (!still) image.dispose();
        if (!mounted) {
          if (still) image.dispose();
          return;
        }
        setState(() {
          _natural ??= size;
          _firstFrame?.dispose();
          _firstFrame = still ? image : null;
        });
      } catch (_) {
        if (mounted) setState(() => _failed = true);
      }
      return;
    }
    try {
      final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
      final descriptor = await ui.ImageDescriptor.encoded(buffer);
      final size = Size(
        descriptor.width.toDouble(),
        descriptor.height.toDouble(),
      );
      ui.Image? first;
      if (widget.kind == MediaKind.gif && mounted && _still) {
        final codec = await descriptor.instantiateCodec();
        first = (await codec.getNextFrame()).image;
        codec.dispose();
      }
      descriptor.dispose();
      buffer.dispose();
      if (!mounted) {
        first?.dispose();
        return;
      }
      setState(() {
        _natural ??= size;
        _firstFrame?.dispose();
        _firstFrame = first;
      });
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  Future<void> _inspectSvg(Uint8List bytes) async {
    try {
      final info = await vg.loadPicture(SvgBytesLoader(bytes), null);
      final size = info.size;
      info.picture.dispose();
      if (mounted) {
        setState(() => _natural ??= size.isEmpty ? const Size(240, 180) : size);
      }
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  Widget _broken(BuildContext context) =>
      widget.fallback?.call(context) ??
      Icon(
        LucideIcons.imageOff,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      );

  @override
  Widget build(BuildContext context) {
    if (_failed && widget.fallback != null) return widget.fallback!(context);
    final tone = skeletonColors(context).bone;
    return LayoutBuilder(
      builder: (context, constraints) {
        final box =
            widget.fit ??
            chatImageBox(
              _natural?.width,
              _natural?.height,
              constraints.maxWidth.isFinite
                  ? constraints.maxWidth
                  : kChatImageMaxWidth,
            );
        final dpr = MediaQuery.devicePixelRatioOf(context);
        final ready =
            (_natural != null || widget.fit != null) &&
            (widget.bytes != null || widget.url != null);
        Widget? image;
        if (_failed) {
          image = Center(child: _broken(context));
        } else if (ready) {
          image = _image(context, box, dpr);
        }
        return Semantics(
          image: true,
          label: widget.semanticLabel,
          child: Material(
            color: tone,
            borderRadius: AppRadius.tileAll,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              key: widget.tapKey,
              onTap: _still
                  ? () => setState(() => _playing = true)
                  : widget.onTap,
              child: SizedBox(
                width: box.width,
                height: box.height,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: image == null
                      ? const SizedBox.expand()
                      : KeyedSubtree(
                          key: ValueKey((_still, _failed)),
                          child: image,
                        ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _image(BuildContext context, Size box, double dpr) {
    final bytes = widget.bytes;
    if (widget.kind == MediaKind.svg) {
      return SvgPicture.memory(
        bytes!,
        fit: widget.fit == null ? BoxFit.contain : BoxFit.cover,
        width: box.width,
        height: box.height,
        errorBuilder: (context, _, _) => Center(child: _broken(context)),
      );
    }
    if (_still && _firstFrame != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          RawImage(image: _firstFrame, fit: BoxFit.cover),
          const Center(child: _GifBadge()),
        ],
      );
    }
    final cacheWidth = (box.width * dpr).round();
    final ImageProvider provider = bytes != null
        ? ResizeImage.resizeIfNeeded(cacheWidth, null, MemoryImage(bytes))
        : ResizeImage.resizeIfNeeded(
            cacheWidth,
            null,
            cachedNetworkImage(widget.url!, headers: widget.headers),
          );
    return Image(
      image: provider,
      fit: BoxFit.cover,
      width: box.width,
      height: box.height,
      gaplessPlayback: true,
      excludeFromSemantics: true,
      errorBuilder: (context, _, _) => Center(child: _broken(context)),
    );
  }
}

class _GifBadge extends StatelessWidget {
  const _GifBadge();

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Colors.black.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(AppRadius.pill),
    ),
    child: const Padding(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.play, size: 14, color: Colors.white),
          SizedBox(width: 4),
          Text(
            'GIF',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 12,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    ),
  );
}
