import 'package:material_ui/material_ui.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:casama_sdk/casama_sdk.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../theme/app_colors.dart';
import '../../ui/smooth_network_image.dart';

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
    final Widget mark;
    if (imageUrl != null) {
      mark = Padding(
        padding: EdgeInsets.all(size * 0.16),
        // Decoded at the tile's size: remote logos are often 512 px or more. The neutral tile is the
        // placeholder; the logo fades in, and one that can't load shows the app's initial.
        child: SmoothNetworkImage(
          imageUrl!,
          fit: BoxFit.contain,
          decodeWidth: (size * MediaQuery.devicePixelRatioOf(context)).ceil(),
          placeholderColor: Colors.transparent,
          error: _initial(scheme.onSurfaceVariant),
        ),
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
