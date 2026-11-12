import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:material_ui/material_ui.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:casama_sdk/casama_sdk.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../core/app_marks.dart';
import '../../core/media_cache.dart';

/// Apps with a bundled brand mark (assets/apps, from Simple Icons, CC0).
const _bundledLogos = {
  'airtable', 'asana', 'atlassian', 'box', 'cloudflare', 'figma', 'github', 'gmail', 'google_calendar', //
  'google_drive', 'hubspot', 'huggingface', 'intercom', 'linear', 'mcp', 'notion', 'posthog', 'sentry', //
  'slack', 'stripe', 'supabase', 'vercel', 'webflow', 'zapier',
};

/// The bundled marks' files, so startup can parse them before the Connections screens open.
List<String> get bundledLogoAssets => [for (final id in _bundledLogos) 'assets/apps/$id.svg'];

Color brandColor(String? hex, Color fallback) {
  final v = hex == null ? null : int.tryParse(hex.replaceFirst('#', ''), radix: 16);
  return v == null ? fallback : Color(0xFF000000 | v);
}

/// An app's mark on a tile in its brand color, like a home-screen icon. Apps without a bundled
/// mark get their initial; custom connections get an icon for their kind.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.appId, this.name = '', this.color, this.icon, this.imageUrl, this.size = 44, this.glow = false});

  /// Catalog app id (stripe, linear…); picks the bundled mark.
  final String? appId;
  final String name;

  /// Brand color, hex without #.
  final String? color;

  /// For custom connections (MCP, OpenAPI, Composio, Pipedream).
  final IconData? icon;

  /// A remote logo (Composio and Pipedream directories).
  final String? imageUrl;
  final double size;

  /// A soft halo in the brand color, for hero placements.
  final bool glow;

  /// The logo for a connection: its catalog app when it has one, otherwise its kind.
  factory AppLogo.forIntegration(Integration i, {CatalogApp? app, double size = 44, Key? key}) => AppLogo(
    key: key,
    appId:
        i.appId ??
        switch (i.kind) {
          IntegrationKind.mcp => 'mcp',
          _ => null,
        },
    name: app?.name ?? i.name,
    color: app?.color,
    icon: i.appId != null
        ? null
        : switch (i.kind) {
            IntegrationKind.mcp => null,
            IntegrationKind.openapi => LucideIcons.braces,
            IntegrationKind.composio => LucideIcons.blocks,
            IntegrationKind.pipedream => LucideIcons.cable,
            IntegrationKind.localMcp => LucideIcons.laptop,
            IntegrationKind.a2a => LucideIcons.bot,
          },
    size: size,
  );

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = scheme.brightness == Brightness.dark;
    final base = brandColor(color, appId == 'mcp' || icon != null ? scheme.primary : scheme.inverseSurface);
    final lightBrand = base.computeLuminance() > 0.55;
    final ink = lightBrand ? const Color(0xFF1B1B1F) : Colors.white;
    final radius = BorderRadius.circular(size * 0.28);
    final hasMark = appId != null && _bundledLogos.contains(appId);
    // A gallery app's mark (D-239) is drawn like a bundled one: tinted on its brand color.
    final galleryMark = hasMark || appId == null ? null : galleryAppMarks[appId];
    final Widget mark;
    if (imageUrl == null && galleryMark != null) {
      mark = Padding(
        padding: EdgeInsets.all(size * 0.24),
        child: _RemoteLogo(galleryMark, size: size, tint: ink, fallback: _initial(ink)),
      );
    } else if (imageUrl != null) {
      mark = Padding(
        padding: EdgeInsets.all(size * 0.16),
        child: _RemoteLogo(imageUrl!, size: size, fallback: _initial(scheme.onSurfaceVariant)),
      );
    } else if (hasMark) {
      mark = Padding(
        padding: EdgeInsets.all(size * 0.24),
        child: SvgPicture.asset('assets/apps/$appId.svg', colorFilter: ColorFilter.mode(ink, BlendMode.srcIn)),
      );
    } else if (icon != null) {
      mark = Icon(icon, size: size * 0.46, color: ink);
    } else {
      mark = _initial(ink);
    }
    // Remote logos are full-color, so they sit on a neutral tile.
    final tile = imageUrl != null ? (dark ? scheme.surfaceContainerHighest : Colors.white) : base;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: imageUrl != null ? null : LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color.lerp(tile, Colors.white, lightBrand ? 0.18 : 0.14)!, tile]),
        color: imageUrl != null ? tile : null,
        // Very dark brands (GitHub, Notion) would vanish on a dark page without an edge.
        border: Border.all(color: dark && base.computeLuminance() < 0.04 ? Colors.white24 : context.appColors.hairline.withValues(alpha: imageUrl != null ? 1 : 0)),
        boxShadow: [
          if (glow)
            BoxShadow(
              color: base.withValues(alpha: dark ? 0.55 : 0.4),
              blurRadius: size * 0.5,
              spreadRadius: size * 0.02,
            ),
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.3 : 0.08),
            blurRadius: size * 0.12,
            offset: Offset(0, size * 0.04),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: mark,
    );
  }

  Widget _initial(Color ink) => Text(
    (name.isEmpty ? '?' : name.characters.first).toUpperCase(),
    style: TextStyle(color: ink, fontWeight: FontWeight.w800, fontSize: size * 0.44, height: 1),
  );
}

/// A directory's logo, SVG or raster: Composio serves SVG (logos.composio.dev), Pipedream PNG, and
/// Flutter's Image can't read SVG. On devices the bytes are fetched once, kept in [MediaCache] and
/// drawn by format; on the web the browser's own <img> draws either (the logo hosts send no CORS
/// headers, so the bytes can't be fetched there). The tile is the placeholder while it loads.
class _RemoteLogo extends StatefulWidget {
  const _RemoteLogo(this.url, {required this.size, required this.fallback, this.tint});

  final String url;
  final double size;

  /// Draws an SVG mark in this one color (gallery marks). The gallery allows cross-origin reads,
  /// so on the web its bytes are fetched like on devices.
  final Color? tint;

  /// Shown when the logo can't load or isn't a picture.
  final Widget fallback;

  @override
  State<_RemoteLogo> createState() => _RemoteLogoState();
}

class _RemoteLogoState extends State<_RemoteLogo> {
  late Future<Uint8List> _bytes = _fetch();

  Future<Uint8List> _fetch() => MediaCache.getOrFetch('logo:${widget.url}', () async {
    final res = await http.get(Uri.parse(widget.url));
    if (res.statusCode != 200 || res.bodyBytes.isEmpty) throw StateError('logo ${res.statusCode}');
    return res.bodyBytes;
  });

  @override
  void didUpdateWidget(_RemoteLogo old) {
    super.didUpdateWidget(old);
    if (old.url != widget.url && (!kIsWeb || widget.tint != null)) _bytes = _fetch();
  }

  /// SVG text starts with markup (an XML prolog, a comment or <svg) after any BOM or whitespace.
  static bool _isSvg(Uint8List b) {
    final head = String.fromCharCodes(b.take(512)).replaceFirst('\uFEFF', '').trimLeft();
    return head.startsWith('<') && head.contains('<svg');
  }

  @override
  Widget build(BuildContext context) {
    final px = (widget.size * MediaQuery.devicePixelRatioOf(context)).ceil();
    if (kIsWeb && widget.tint == null) {
      return Image.network(
        widget.url,
        fit: BoxFit.contain,
        webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
        errorBuilder: (_, _, _) => Center(child: widget.fallback),
      );
    }
    return FutureBuilder<Uint8List>(
      future: _bytes,
      builder: (context, snap) {
        if (snap.hasError) return Center(child: widget.fallback);
        final bytes = snap.data;
        if (bytes == null) return const SizedBox.expand();
        final child = _isSvg(bytes)
            ? SvgPicture.memory(
                bytes,
                fit: BoxFit.contain,
                colorFilter: widget.tint == null ? null : ColorFilter.mode(widget.tint!, BlendMode.srcIn),
                errorBuilder: (_, _, _) => Center(child: widget.fallback),
              )
            // Decoded at the tile's size: remote logos are often 512 px or more.
            : Image.memory(bytes, fit: BoxFit.contain, cacheWidth: px, errorBuilder: (_, _, _) => Center(child: widget.fallback));
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: AppMotion.of(context, AppMotion.duration),
          curve: AppMotion.curve,
          builder: (_, t, c) => Opacity(opacity: t, child: c),
          child: child,
        );
      },
    );
  }
}
