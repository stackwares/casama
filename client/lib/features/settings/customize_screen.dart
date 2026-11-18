import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/widgets.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_tokens.dart';
import '../../theme/appearance.dart';
import '../../theme/presets.dart';
import '../../theme/wallpaper.dart';
import '../../ui/page.dart';
import '../../ui/segmented.dart';
import '../../ui/shell_header.dart';
import 'appearance_preview.dart';
import 'appearance_screen.dart' show currentTheme, saveCurrentLook;
import 'background_panel.dart';
import 'colors_panel.dart';
import 'fonts_panel.dart';

/// The three parts of a look that Customize changes.
enum LookPart {
  colors,
  background,
  fonts;

  /// The part a link names (`?tab=fonts`); colors when it names none.
  static LookPart named(String? name) =>
      LookPart.values.asNameMap()[name] ?? LookPart.colors;
}

/// Appearance → Customize: colors, background and fonts on one page, under a live preview that
/// stays in view (pinned above on phones, beside on wide windows), so every tap shows its result
/// without scrolling or going back. A changed look can be saved as a theme from the header.
class CustomizeScreen extends ConsumerStatefulWidget {
  const CustomizeScreen({super.key, this.initial = LookPart.colors});
  final LookPart initial;

  @override
  ConsumerState<CustomizeScreen> createState() => _CustomizeScreenState();
}

class _CustomizeScreenState extends ConsumerState<CustomizeScreen> {
  late var _part = widget.initial;

  /// Shows the preview in the other brightness, without changing the app's own.
  var _flipped = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final appearance = ref.watch(appearanceProvider);
    final custom =
        currentTheme(appearance, ref.watch(savedThemesProvider)) == null;
    final tabs = AppSegmentedControl<LookPart>(
      key: const Key('customizeTabs'),
      values: LookPart.values,
      labels: {
        LookPart.colors: l10n.customizeColors,
        LookPart.background: l10n.background,
        LookPart.fonts: l10n.fonts,
      },
      icons: const {
        LookPart.colors: LucideIcons.palette,
        LookPart.background: LucideIcons.image,
        LookPart.fonts: LucideIcons.type,
      },
      groupValue: _part,
      onValueChanged: (p) => setState(() => _part = p),
    );
    final panel = switch (_part) {
      LookPart.colors => const ColorsPanel(key: ValueKey(LookPart.colors)),
      LookPart.background => const BackgroundPanel(
        key: ValueKey(LookPart.background),
      ),
      LookPart.fonts => const FontsPanel(key: ValueKey(LookPart.fonts)),
    };

    return Scaffold(
      appBar: ShellHeader(
        title: l10n.customize,
        actions: [
          if (custom)
            Padding(
              padding: const EdgeInsets.only(right: AppSpace.xxs),
              child: TextButton.icon(
                key: const Key('saveTheme'),
                onPressed: () => saveCurrentLook(context, ref),
                icon: const Icon(LucideIcons.bookmarkPlus, size: 18),
                label: Text(l10n.save),
              ),
            ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 760) {
            final side = math.min(400.0, constraints.maxWidth * 0.4);
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    children: [
                      _Centered(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpace.gutter,
                          AppSpace.xs,
                          AppSpace.gutter,
                          AppSpace.xs,
                        ),
                        child: tabs,
                      ),
                      Expanded(child: panel),
                    ],
                  ),
                ),
                SizedBox(
                  width: side,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      0,
                      AppSpace.xs,
                      AppSpace.gutter,
                      AppSpace.gutter,
                    ),
                    child: _preview(
                      appearance,
                      (constraints.maxHeight * 0.6).clamp(220.0, 460.0),
                    ),
                  ),
                ),
              ],
            );
          }
          // Phones: the preview and the tabs stay put while the choices scroll under them.
          final height = constraints.maxHeight < 560
              ? 112.0
              : constraints.maxHeight < 720
              ? 140.0
              : 168.0;
          return Column(
            children: [
              _Centered(
                padding: const EdgeInsets.fromLTRB(
                  AppSpace.gutter,
                  AppSpace.xs,
                  AppSpace.gutter,
                  AppSpace.xs,
                ),
                child: Column(
                  children: [
                    _preview(appearance, height),
                    const SizedBox(height: AppSpace.sm),
                    tabs,
                  ],
                ),
              ),
              Expanded(child: panel),
            ],
          );
        },
      ),
    );
  }

  Widget _preview(Appearance appearance, double height) {
    final ambient = Theme.of(context);
    final dark = (ambient.brightness == Brightness.dark) != _flipped;
    final theme = _flipped
        ? (dark ? AppTheme.dark(appearance) : AppTheme.light(appearance))
        : ambient;
    // The wallpaper is passed in so the preview always shows it, even when it's set to chats only.
    final wallpaper = WallpaperTheme.of(
      appearance.wallpaper.copyWith(everywhere: true),
      theme.colorScheme,
    );
    return Stack(
      children: [
        Theme(
          data: theme,
          child: AppearancePreview(
            key: const Key('customizePreview'),
            wallpaper: wallpaper,
            height: height,
          ),
        ),
        // Top left: the chat's bubbles sit at the bottom and to the right, so this corner is free.
        Positioned(
          top: AppSpace.xs,
          left: AppSpace.xs,
          child: _PeekButton(
            dark: dark,
            onPressed: () => setState(() => _flipped = !_flipped),
          ),
        ),
      ],
    );
  }
}

/// Light or dark for the preview only: a small round button on its corner.
class _PeekButton extends StatelessWidget {
  const _PeekButton({required this.dark, required this.onPressed});
  final bool dark;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final l10n = context.l10n;
    return Tooltip(
      message: dark ? l10n.galleryPreviewLight : l10n.galleryPreviewDark,
      child: Material(
        color: scheme.surface.withValues(alpha: 0.86),
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: const Key('customizePeek'),
          onTap: onPressed,
          child: SizedBox(
            width: 36,
            height: 36,
            child: Icon(
              dark ? LucideIcons.sun : LucideIcons.moon,
              size: 18,
              color: scheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}

/// [child] at the page's width, centered on wide windows.
class _Centered extends StatelessWidget {
  const _Centered({required this.padding, required this.child});
  final EdgeInsets padding;
  final Widget child;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: kPageMaxWidth),
      child: Padding(padding: padding, child: child),
    ),
  );
}
