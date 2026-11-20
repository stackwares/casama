import 'package:material_ui/material_ui.dart';

import '../../core/widgets.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../ui/painted_cover.dart';

/// The painted covers a project can pick, by name (`project-<name>` in the app's art).
const projectCovers = [
  'sailboat',
  'mountain',
  'seedling',
  'compass',
  'lantern',
  'telescope',
  'map',
  'chess',
];

/// The bundled picture for a project's [cover], or null when it has none (or the app doesn't know
/// the name, which then draws the fallback tile).
String? projectCoverAsset(String? cover) =>
    cover == null ? null : paintedAsset('project-$cover');

/// A project's cover picked big, as a wide banner at the top of its screen.
class ProjectCoverBanner extends StatelessWidget {
  const ProjectCoverBanner({
    super.key,
    required this.cover,
    required this.seed,
    required this.icon,
  });

  final String cover;
  final String seed;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpace.md),
    child: ExcludeSemantics(
      child: ClipRRect(
        borderRadius: AppRadius.cardAll,
        child: AspectRatio(
          aspectRatio: 2.4,
          child: PaintedArt(
            key: const Key('projectCoverBanner'),
            seed: seed,
            asset: projectCoverAsset(cover),
            icon: icon,
            iconScale: 0.3,
          ),
        ),
      ),
    ),
  );
}

/// A row of the painted covers plus None, scrolling sideways; the picked one is ringed.
class ProjectCoverPicker extends StatelessWidget {
  const ProjectCoverPicker({
    super.key,
    required this.value,
    required this.seed,
    required this.icon,
    required this.onChanged,
    this.size = 56,
  });

  /// The picked cover's name, or null for none.
  final String? value;
  final String seed;

  /// Drawn on None, and on a cover whose picture is missing.
  final IconData icon;
  final ValueChanged<String?>? onChanged;
  final double size;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    final radius = size * 0.26;
    Widget option({
      required String? name,
      required String label,
      required Widget child,
    }) {
      final selected = value == name;
      return Semantics(
        button: true,
        selected: selected,
        label: label,
        child: Tooltip(
          message: label,
          child: InkWell(
            key: Key('projectCover-${name ?? 'none'}'),
            borderRadius: BorderRadius.circular(radius + 4),
            onTap: onChanged == null || selected
                ? null
                : () => onChanged!(name),
            child: AnimatedContainer(
              duration: AppMotion.of(context, AppMotion.fast),
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(radius + 3),
                border: Border.all(
                  color: selected ? scheme.primary : Colors.transparent,
                  width: 2.5,
                ),
              ),
              child: ExcludeSemantics(child: child),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: size + 11,
      child: ListView(
        key: const Key('projectCoverPicker'),
        scrollDirection: Axis.horizontal,
        children: [
          option(
            name: null,
            label: l10n.projectCoverNone,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(radius),
              ),
              alignment: Alignment.center,
              child: Icon(
                icon,
                size: size * 0.4,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          for (final c in projectCovers) ...[
            const SizedBox(width: AppSpace.xxs),
            option(
              name: c,
              label: l10n.projectCoverName(c),
              child: PaintedCover(
                size: size,
                radius: radius,
                seed: seed,
                asset: projectCoverAsset(c),
                icon: icon,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
