// Made by scripts/casama-looks.mts from client/looks; do not edit.

import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:material_ui/material_ui.dart';

import 'doodles.dart';
import 'mesh_gradient.dart';

/// A mesh gradient behind the pattern: nine colors on a gently warped 3×3 grid, with hand-picked
/// night versions. `theme` follows the chosen color scheme; `flat` is its plain surface.
enum WallpaperPalette {
  theme('Theme', []),

  /// No gradient at all: the theme's own surface color, flat.
  flat('Flat', []),
  casama(
    'Casama',
    [
      Color(0xFFF1DBFF),
      Color(0xFFFED3EA),
      Color(0xFFF9E3F7),
      Color(0xFFE5D1FE),
      Color(0xFFF8E1F9),
      Color(0xFFFFCFE0),
      Color(0xFFDDDEFF),
      Color(0xFFF5CAF6),
      Color(0xFFEAE3FF),
    ],
    dark: [
      Color(0xFF351C43),
      Color(0xFF3F102E),
      Color(0xFF3F253D),
      Color(0xFF28103E),
      Color(0xFF3D223F),
      Color(0xFF3E0A24),
      Color(0xFF221E47),
      Color(0xFF310B34),
      Color(0xFF31234A),
    ],
    points: [
      Offset.zero,
      Offset(0.62, 0),
      Offset(1, 0),
      Offset(0, 0.38),
      Offset(0.4, 0.58),
      Offset(1, 0.46),
      Offset(0, 1),
      Offset(0.55, 1),
      Offset(1, 1),
    ],
  ),
  lavender(
    'Lavender',
    [
      Color(0xFFE7E4FE),
      Color(0xFFE6DAFE),
      Color(0xFFF6E9FD),
      Color(0xFFD7DBFF),
      Color(0xFFEBE6FE),
      Color(0xFFEFDCFE),
      Color(0xFFE4EBFE),
      Color(0xFFDED8FF),
      Color(0xFFF6DFFB),
    ],
    dark: [
      Color(0xFF2C254A),
      Color(0xFF2C1A45),
      Color(0xFF3D2B45),
      Color(0xFF1C1A48),
      Color(0xFF302847),
      Color(0xFF331D42),
      Color(0xFF242E4C),
      Color(0xFF241844),
      Color(0xFF3A2040),
    ],
    points: [
      Offset.zero,
      Offset(0.4, 0),
      Offset(1, 0),
      Offset(0, 0.55),
      Offset(0.62, 0.42),
      Offset(1, 0.6),
      Offset(0, 1),
      Offset(0.45, 1),
      Offset(1, 1),
    ],
  ),
  cotton(
    'Cotton candy',
    [
      Color(0xFFFFD9E6),
      Color(0xFFEEE7FE),
      Color(0xFFC9E5FF),
      Color(0xFFFDE7FA),
      Color(0xFFE9E6FF),
      Color(0xFFFFDAE1),
      Color(0xFFC2E7FE),
      Color(0xFFFEDDEE),
      Color(0xFFE7EFFE),
    ],
    dark: [
      Color(0xFF45142B),
      Color(0xFF34284A),
      Color(0xFF012743),
      Color(0xFF432841),
      Color(0xFF2E2848),
      Color(0xFF471423),
      Color(0xFF00293C),
      Color(0xFF451A34),
      Color(0xFF26324E),
    ],
    points: [
      Offset.zero,
      Offset(0.55, 0),
      Offset(1, 0),
      Offset(0, 0.45),
      Offset(0.35, 0.4),
      Offset(1, 0.62),
      Offset(0, 1),
      Offset(0.65, 1),
      Offset(1, 1),
    ],
  ),
  peach(
    'Peach',
    [
      Color(0xFFFFE1D1),
      Color(0xFFFED6D2),
      Color(0xFFFFEBD5),
      Color(0xFFFEDADE),
      Color(0xFFFFE5DA),
      Color(0xFFFEDEC4),
      Color(0xFFFBE9CA),
      Color(0xFFFED7CD),
      Color(0xFFFEDEE7),
    ],
    dark: [
      Color(0xFF4A1923),
      Color(0xFF3F102E),
      Color(0xFF4E2620),
      Color(0xFF3D173B),
      Color(0xFF49212B),
      Color(0xFF481418),
      Color(0xFF4B2314),
      Color(0xFF411127),
      Color(0xFF3C1E43),
    ],
    points: [
      Offset.zero,
      Offset(0.45, 0),
      Offset(1, 0),
      Offset(0, 0.6),
      Offset(0.58, 0.55),
      Offset(1, 0.35),
      Offset(0, 1),
      Offset(0.4, 1),
      Offset(1, 1),
    ],
  ),
  sunset(
    'Sunset',
    [
      Color(0xFFFED4B9),
      Color(0xFFFEC8C7),
      Color(0xFFFFD3E6),
      Color(0xFFFEDFB6),
      Color(0xFFFEDBD5),
      Color(0xFFF0C7F9),
      Color(0xFFFECEBE),
      Color(0xFFFFD0D9),
      Color(0xFFE3D6FE),
    ],
    dark: [
      Color(0xFF420910),
      Color(0xFF340424),
      Color(0xFF341541),
      Color(0xFF491501),
      Color(0xFF45142B),
      Color(0xFF191140),
      Color(0xFF3C0519),
      Color(0xFF370E35),
      Color(0xFF0D1E4A),
    ],
    points: [
      Offset.zero,
      Offset(0.6, 0),
      Offset(1, 0),
      Offset(0, 0.4),
      Offset(0.45, 0.62),
      Offset(1, 0.52),
      Offset(0, 1),
      Offset(0.5, 1),
      Offset(1, 1),
    ],
  ),
  mint(
    'Mint',
    [
      Color(0xFFCDF6E3),
      Color(0xFFBAF2E6),
      Color(0xFFDCF7E1),
      Color(0xFFB7F0DB),
      Color(0xFFD5F4E2),
      Color(0xFFC2F3F2),
      Color(0xFFDFF7DA),
      Color(0xFFBBF2E2),
      Color(0xFFC9F5F7),
    ],
    dark: [
      Color(0xFF013927),
      Color(0xFF023029),
      Color(0xFF193C22),
      Color(0xFF012D21),
      Color(0xFF0B3925),
      Color(0xFF003434),
      Color(0xFF203B1A),
      Color(0xFF023127),
      Color(0xFF01373A),
    ],
    points: [
      Offset.zero,
      Offset(0.38, 0),
      Offset(1, 0),
      Offset(0, 0.5),
      Offset(0.6, 0.45),
      Offset(1, 0.58),
      Offset(0, 1),
      Offset(0.6, 1),
      Offset(1, 1),
    ],
  ),
  ocean(
    'Ocean',
    [
      Color(0xFFCCE9FE),
      Color(0xFFB4ECFA),
      Color(0xFFDFEDFE),
      Color(0xFFBDF4F6),
      Color(0xFFCEF0FE),
      Color(0xFFC6E1FF),
      Color(0xFFB9EAFF),
      Color(0xFFC2F3F2),
      Color(0xFFD9E5FE),
    ],
    dark: [
      Color(0xFF002C45),
      Color(0xFF002B33),
      Color(0xFF19304E),
      Color(0xFF023336),
      Color(0xFF003343),
      Color(0xFF002342),
      Color(0xFF012A37),
      Color(0xFF003434),
      Color(0xFF16264D),
    ],
    points: [
      Offset.zero,
      Offset(0.58, 0),
      Offset(1, 0),
      Offset(0, 0.62),
      Offset(0.42, 0.48),
      Offset(1, 0.4),
      Offset(0, 1),
      Offset(0.48, 1),
      Offset(1, 1),
    ],
  ),
  forest(
    'Forest',
    [
      Color(0xFFDAF0CF),
      Color(0xFFC3EED0),
      Color(0xFFEAF0CA),
      Color(0xFFC3F1DC),
      Color(0xFFD9F0D3),
      Color(0xFFD8E9BE),
      Color(0xFFEFEDCB),
      Color(0xFFC8ECCE),
      Color(0xFFC6F3E6),
    ],
    dark: [
      Color(0xFF03361C),
      Color(0xFF012D24),
      Color(0xFF1F3710),
      Color(0xFF01302C),
      Color(0xFF013620),
      Color(0xFF032F09),
      Color(0xFF28350B),
      Color(0xFF002D21),
      Color(0xFF003434),
    ],
    points: [
      Offset.zero,
      Offset(0.5, 0),
      Offset(1, 0),
      Offset(0, 0.42),
      Offset(0.62, 0.6),
      Offset(1, 0.55),
      Offset(0, 1),
      Offset(0.38, 1),
      Offset(1, 1),
    ],
  ),
  graphite(
    'Graphite',
    [
      Color(0xFFE4E8ED),
      Color(0xFFDDE2E9),
      Color(0xFFF1EEEA),
      Color(0xFFDFE6EB),
      Color(0xFFEAEDF1),
      Color(0xFFDEE1EA),
      Color(0xFFEFEAE6),
      Color(0xFFE0E5EB),
      Color(0xFFE3E9EC),
    ],
    dark: [
      Color(0xFF252D36),
      Color(0xFF1F2630),
      Color(0xFF383229),
      Color(0xFF202A32),
      Color(0xFF2A323A),
      Color(0xFF212530),
      Color(0xFF372D26),
      Color(0xFF222933),
      Color(0xFF222E34),
    ],
    points: [
      Offset.zero,
      Offset(0.5, 0),
      Offset(1, 0),
      Offset(0, 0.5),
      Offset(0.5, 0.5),
      Offset(1, 0.5),
      Offset(0, 1),
      Offset(0.5, 1),
      Offset(1, 1),
    ],
  ),
  northern(
    'Northern',
    [
      Color(0xFFA5E9CA),
      Color(0xFFA6EDF0),
      Color(0xFFDBCAFE),
      Color(0xFFC9EDC1),
      Color(0xFFB7F0FE),
      Color(0xFFF1C6FB),
      Color(0xFF9DEDE2),
      Color(0xFFBFD0FF),
      Color(0xFFFECEE8),
    ],
    dark: [
      Color(0xFF002216),
      Color(0xFF02282A),
      Color(0xFF1F0A38),
      Color(0xFF082E00),
      Color(0xFF002E38),
      Color(0xFF2C0933),
      Color(0xFF012521),
      Color(0xFF090F3C),
      Color(0xFF3C0B2B),
    ],
    points: [
      Offset.zero,
      Offset(0.35, 0),
      Offset(1, 0),
      Offset(0, 0.58),
      Offset(0.55, 0.38),
      Offset(1, 0.65),
      Offset(0, 1),
      Offset(0.62, 1),
      Offset(1, 1),
    ],
  ),
  twilight(
    'Twilight',
    [
      Color(0xFFCBD0FE),
      Color(0xFFF3CAFC),
      Color(0xFFFFD6D7),
      Color(0xFFDECEFE),
      Color(0xFFFFD3E6),
      Color(0xFFFEDDCB),
      Color(0xFFB7D2FE),
      Color(0xFFF8C4F2),
      Color(0xFFFEDAB2),
    ],
    dark: [
      Color(0xFF130F3D),
      Color(0xFF2F0C37),
      Color(0xFF460D17),
      Color(0xFF220D3C),
      Color(0xFF40112B),
      Color(0xFF441B01),
      Color(0xFF00123B),
      Color(0xFF2F072D),
      Color(0xFF361F00),
    ],
    points: [
      Offset.zero,
      Offset(0.62, 0),
      Offset(1, 0),
      Offset(0, 0.35),
      Offset(0.38, 0.55),
      Offset(1, 0.5),
      Offset(0, 1),
      Offset(0.42, 1),
      Offset(1, 1),
    ],
  ),
  berry(
    'Berry',
    [
      Color(0xFFFEBAD9),
      Color(0xFFF0C7F9),
      Color(0xFFFED5DA),
      Color(0xFFFEC2EF),
      Color(0xFFFFD3EA),
      Color(0xFFD9C6FE),
      Color(0xFFFFD1D3),
      Color(0xFFF7BFF1),
      Color(0xFFD9D5FE),
    ],
    dark: [
      Color(0xFF2E001B),
      Color(0xFF2C0933),
      Color(0xFF43101C),
      Color(0xFF31062A),
      Color(0xFF3E122E),
      Color(0xFF1D0736),
      Color(0xFF420914),
      Color(0xFF2C042A),
      Color(0xFF201443),
    ],
    points: [
      Offset.zero,
      Offset(0.45, 0),
      Offset(1, 0),
      Offset(0, 0.48),
      Offset(0.65, 0.52),
      Offset(1, 0.38),
      Offset(0, 1),
      Offset(0.55, 1),
      Offset(1, 1),
    ],
  ),
  citrus(
    'Citrus',
    [
      Color(0xFFFEEBA6),
      Color(0xFFFEDFBB),
      Color(0xFFE4F4B8),
      Color(0xFFFFDDC7),
      Color(0xFFFFEDC0),
      Color(0xFFCCF6C3),
      Color(0xFFFFE4B8),
      Color(0xFFFED8C8),
      Color(0xFFF3EFB0),
    ],
    dark: [
      Color(0xFF03392B),
      Color(0xFF023309),
      Color(0xFF023737),
      Color(0xFF1C2F00),
      Color(0xFF013E2A),
      Color(0xFF01323C),
      Color(0xFF02361C),
      Color(0xFF212900),
      Color(0xFF013831),
    ],
    points: [
      Offset.zero,
      Offset(0.55, 0),
      Offset(1, 0),
      Offset(0, 0.62),
      Offset(0.4, 0.42),
      Offset(1, 0.48),
      Offset(0, 1),
      Offset(0.6, 1),
      Offset(1, 1),
    ],
  ),
  reef(
    'Reef',
    [
      Color(0xFFA0E6EA),
      Color(0xFFADEEDB),
      Color(0xFFC1DEFE),
      Color(0xFFC0EED4),
      Color(0xFFBAF0F6),
      Color(0xFF9FDFFE),
      Color(0xFFA9EEE4),
      Color(0xFFC5D8FE),
      Color(0xFFC6EDCD),
    ],
    dark: [
      Color(0xFF012022),
      Color(0xFF002921),
      Color(0xFF001F3D),
      Color(0xFF012E1B),
      Color(0xFF022F33),
      Color(0xFF001B27),
      Color(0xFF012825),
      Color(0xFF071742),
      Color(0xFF002F10),
    ],
    points: [
      Offset.zero,
      Offset(0.4, 0),
      Offset(1, 0),
      Offset(0, 0.4),
      Offset(0.58, 0.62),
      Offset(1, 0.58),
      Offset(0, 1),
      Offset(0.45, 1),
      Offset(1, 1),
    ],
  );

  const WallpaperPalette(
    this.label,
    this.light, {
    this.dark,
    this.points = MeshGradient.evenPoints,
  });
  final String label;
  final List<Color> light;
  final List<Color>? dark;

  /// Where the nine colors sit, as fractions of the window, row by row from the top left.
  final List<Offset> points;
}

/// Doodle patterns drawn over the wallpaper gradient, Telegram style, from Lucide drawings.
enum WallpaperPattern {
  none('Plain', []),
  clouds('Clouds', [
    Doodle([DoodlePath('M17.5 19H9a7 7 0 1 1 6.71-9h1.79a4.5 4.5 0 1 1 0 9Z')]),
    Doodle([
      DoodlePath('M12 2v2'),
      DoodlePath('m4.93 4.93 1.41 1.41'),
      DoodlePath('M20 12h2'),
      DoodlePath('m19.07 4.93-1.41 1.41'),
      DoodlePath('M15.947 12.65a4 4 0 0 0-5.925-4.128'),
      DoodlePath('M13 22H7a5 5 0 1 1 4.9-6H13a3 3 0 0 1 0 6Z'),
    ]),
    Doodle([
      DoodlePath(
        'M11.525 2.295a.53.53 0 0 1 .95 0l2.31 4.679a2.123 2.123 0 0 0 1.595 1.16l5.166.756a.53.53 0 0 1 .294.904l-3.736 3.638a2.123 2.123 0 0 0-.611 1.878l.882 5.14a.53.53 0 0 1-.771.56l-4.618-2.428a2.122 2.122 0 0 0-1.973 0L6.396 21.01a.53.53 0 0 1-.77-.56l.881-5.139a2.122 2.122 0 0 0-.611-1.879L2.16 9.795a.53.53 0 0 1 .294-.906l5.165-.755a2.122 2.122 0 0 0 1.597-1.16z',
      ),
    ]),
    Doodle([
      DoodlePath(
        'M11.017 2.814a1 1 0 0 1 1.966 0l1.051 5.558a2 2 0 0 0 1.594 1.594l5.558 1.051a1 1 0 0 1 0 1.966l-5.558 1.051a2 2 0 0 0-1.594 1.594l-1.051 5.558a1 1 0 0 1-1.966 0l-1.051-5.558a2 2 0 0 0-1.594-1.594l-5.558-1.051a1 1 0 0 1 0-1.966l5.558-1.051a2 2 0 0 0 1.594-1.594z',
      ),
    ]),
    Doodle([
      DoodlePath('M13 16a3 3 0 0 1 0 6H7a5 5 0 1 1 4.9-6z'),
      DoodlePath(
        'M18.376 14.512a6 6 0 0 0 3.461-4.127c.148-.625-.659-.97-1.248-.714a4 4 0 0 1-5.259-5.26c.255-.589-.09-1.395-.716-1.248a6 6 0 0 0-4.594 5.36',
      ),
    ]),
    Doodle([
      DoodlePath(
        'M20.985 12.486a9 9 0 1 1-9.473-9.472c.405-.022.617.46.402.803a6 6 0 0 0 8.268 8.268c.344-.215.825-.004.803.401',
      ),
    ]),
    Doodle([
      DoodlePath(
        'M11.017 2.814a1 1 0 0 1 1.966 0l1.051 5.558a2 2 0 0 0 1.594 1.594l5.558 1.051a1 1 0 0 1 0 1.966l-5.558 1.051a2 2 0 0 0-1.594 1.594l-1.051 5.558a1 1 0 0 1-1.966 0l-1.051-5.558a2 2 0 0 0-1.594-1.594l-5.558-1.051a1 1 0 0 1 0-1.966l5.558-1.051a2 2 0 0 0 1.594-1.594z',
      ),
      DoodlePath('M20 2v4'),
      DoodlePath('M22 4h-4'),
      DoodleCircle(4, 20, 2),
    ]),
    Doodle([
      DoodlePath('M20.341 6.484A10 10 0 0 1 10.266 21.85'),
      DoodlePath('M3.659 17.516A10 10 0 0 1 13.74 2.152'),
      DoodleCircle(12, 12, 3),
      DoodleCircle(19, 5, 2),
      DoodleCircle(5, 19, 2),
    ]),
    Doodle([
      DoodlePath('M22 17a10 10 0 0 0-20 0'),
      DoodlePath('M6 17a6 6 0 0 1 12 0'),
      DoodlePath('M10 17a2 2 0 0 1 4 0'),
    ]),
  ]),
  doodles('Doodles', [
    Doodle([
      DoodlePath(
        'M2.992 16.342a2 2 0 0 1 .094 1.167l-1.065 3.29a1 1 0 0 0 1.236 1.168l3.413-.998a2 2 0 0 1 1.099.092 10 10 0 1 0-4.777-4.719',
      ),
    ]),
    Doodle([
      DoodlePath(
        'M2 9.5a5.5 5.5 0 0 1 9.591-3.676.56.56 0 0 0 .818 0A5.49 5.49 0 0 1 22 9.5c0 2.29-1.5 4-3 5.5l-5.492 5.313a2 2 0 0 1-3 .019L5 15c-1.5-1.5-3-3.2-3-5.5',
      ),
    ]),
    Doodle([
      DoodlePath(
        'M11.525 2.295a.53.53 0 0 1 .95 0l2.31 4.679a2.123 2.123 0 0 0 1.595 1.16l5.166.756a.53.53 0 0 1 .294.904l-3.736 3.638a2.123 2.123 0 0 0-.611 1.878l.882 5.14a.53.53 0 0 1-.771.56l-4.618-2.428a2.122 2.122 0 0 0-1.973 0L6.396 21.01a.53.53 0 0 1-.77-.56l.881-5.139a2.122 2.122 0 0 0-.611-1.879L2.16 9.795a.53.53 0 0 1 .294-.906l5.165-.755a2.122 2.122 0 0 0 1.597-1.16z',
      ),
    ]),
    Doodle([
      DoodlePath('M15 10V9'),
      DoodlePath('M16.472 15a6 6 0 01-8.943 0'),
      DoodlePath('M9 10V9'),
      DoodleCircle(12, 12, 10),
    ]),
    Doodle([
      DoodlePath('M10 2v2'),
      DoodlePath('M14 2v2'),
      DoodlePath(
        'M16 8a1 1 0 0 1 1 1v8a4 4 0 0 1-4 4H7a4 4 0 0 1-4-4V9a1 1 0 0 1 1-1h14a4 4 0 1 1 0 8h-1',
      ),
      DoodlePath('M6 2v2'),
    ]),
    Doodle([
      DoodlePath('M21 16V3a1 1 0 0 0-1.28-.96l-10 2.917a1 1 0 0 0-.72.96V19'),
      DoodleCircle(18, 16, 3),
      DoodleCircle(6, 19, 3),
    ]),
    Doodle([
      DoodlePath('M12 15v5s3.03-.55 4-2c1.08-1.62 0-5 0-5'),
      DoodlePath(
        'M4.5 16.5c-1.5 1.26-2 5-2 5s3.74-.5 5-2c.71-.84.7-2.13-.09-2.91a2.18 2.18 0 0 0-2.91-.09',
      ),
      DoodlePath(
        'M9 12a22 22 0 0 1 2-3.95A12.88 12.88 0 0 1 22 2c0 2.72-.78 7.5-6 11a22.4 22.4 0 0 1-4 2z',
      ),
      DoodlePath('M9 12H4s.55-3.03 2-4c1.62-1.08 5 .05 5 .05'),
    ]),
    Doodle([
      DoodlePath('M12 7v14'),
      DoodlePath('M20 11v8a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2v-8'),
      DoodlePath(
        'M7.5 7a1 1 0 0 1 0-5A4.8 8 0 0 1 12 7a4.8 8 0 0 1 4.5-5 1 1 0 0 1 0 5',
      ),
      DoodleRect(3, 7, 18, 4, rx: 1, ry: 1),
    ]),
    Doodle([
      DoodleCircle(12, 12, 4),
      DoodlePath('M12 2v2'),
      DoodlePath('M12 20v2'),
      DoodlePath('m4.93 4.93 1.41 1.41'),
      DoodlePath('m17.66 17.66 1.41 1.41'),
      DoodlePath('M2 12h2'),
      DoodlePath('M20 12h2'),
      DoodlePath('m6.34 17.66-1.41 1.41'),
      DoodlePath('m19.07 4.93-1.41 1.41'),
    ]),
    Doodle([
      DoodlePath(
        'M12 5c.67 0 1.35.09 2 .26 1.78-2 5.03-2.84 6.42-2.26 1.4.58-.42 7-.42 7 .57 1.07 1 2.24 1 3.44C21 17.9 16.97 21 12 21s-9-3-9-7.56c0-1.25.5-2.4 1-3.44 0 0-1.89-6.42-.5-7 1.39-.58 4.72.23 6.5 2.23A9.04 9.04 0 0 1 12 5Z',
      ),
      DoodlePath('M8 14v.5'),
      DoodlePath('M16 14v.5'),
      DoodlePath('M11.25 16.25h1.5L12 17l-.75-.75Z'),
    ]),
    Doodle([
      DoodlePath('M12 8V4H8'),
      DoodleRect(4, 8, 16, 12, rx: 2, ry: 2),
      DoodlePath('M2 14h2'),
      DoodlePath('M20 14h2'),
      DoodlePath('M15 13v2'),
      DoodlePath('M9 13v2'),
    ]),
    Doodle([
      DoodlePath(
        'M21.174 6.812a1 1 0 0 0-3.986-3.987L3.842 16.174a2 2 0 0 0-.5.83l-1.321 4.352a.5.5 0 0 0 .623.622l4.353-1.32a2 2 0 0 0 .83-.497z',
      ),
      DoodlePath('m15 5 4 4'),
    ]),
    Doodle([
      DoodlePath(
        'M13.997 4a2 2 0 0 1 1.76 1.05l.486.9A2 2 0 0 0 18.003 7H20a2 2 0 0 1 2 2v9a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V9a2 2 0 0 1 2-2h1.997a2 2 0 0 0 1.759-1.048l.489-.904A2 2 0 0 1 10.004 4z',
      ),
      DoodleCircle(12, 13, 3),
    ]),
    Doodle([
      DoodlePath('M12 13v7a2 2 0 0 0 4 0'),
      DoodlePath('M12 2v2'),
      DoodlePath(
        'M20.992 13a1 1 0 0 0 .97-1.274 10.284 10.284 0 0 0-19.923 0A1 1 0 0 0 3 13z',
      ),
    ]),
    Doodle([
      DoodlePath(
        'M3 14h3a2 2 0 0 1 2 2v3a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-7a9 9 0 0 1 18 0v7a2 2 0 0 1-2 2h-1a2 2 0 0 1-2-2v-3a2 2 0 0 1 2-2h3',
      ),
    ]),
    Doodle([
      DoodleLine(6, 11, 10, 11),
      DoodleLine(8, 9, 8, 13),
      DoodleLine(15, 12, 15.01, 12),
      DoodleLine(18, 10, 18.01, 10),
      DoodlePath(
        'M17.32 5H6.68a4 4 0 0 0-3.978 3.59c-.006.052-.01.101-.017.152C2.604 9.416 2 14.456 2 16a3 3 0 0 0 3 3c1 0 1.5-.5 2-1l1.414-1.414A2 2 0 0 1 9.828 16h4.344a2 2 0 0 1 1.414.586L17 18c.5.5 1 1 2 1a3 3 0 0 0 3-3c0-1.545-.604-6.584-.685-7.258-.007-.05-.011-.1-.017-.151A4 4 0 0 0 17.32 5z',
      ),
    ]),
  ]),
  treats('Treats', [
    Doodle([
      DoodlePath('m7 11 4.08 10.35a1 1 0 0 0 1.84 0L17 11'),
      DoodlePath('M17 7A5 5 0 0 0 7 7'),
      DoodlePath('M17 7a2 2 0 0 1 0 4H7a2 2 0 0 1 0-4'),
    ]),
    Doodle([
      DoodlePath('M20 21v-8a2 2 0 0 0-2-2H6a2 2 0 0 0-2 2v8'),
      DoodlePath('M4 16s.5-1 2-1 2.5 2 4 2 2.5-2 4-2 2.5 2 4 2 2-1 2-1'),
      DoodlePath('M2 21h20'),
      DoodlePath('M7 8v3'),
      DoodlePath('M12 8v3'),
      DoodlePath('M17 8v3'),
      DoodlePath('M7 4h.01'),
      DoodlePath('M12 4h.01'),
      DoodlePath('M17 4h.01'),
    ]),
    Doodle([
      DoodlePath('M10 7v10.9'),
      DoodlePath('M14 6.1V17'),
      DoodlePath(
        'M16 7V3a1 1 0 0 1 1.707-.707 2.5 2.5 0 0 0 2.152.717 1 1 0 0 1 1.131 1.131 2.5 2.5 0 0 0 .717 2.152A1 1 0 0 1 21 8h-4',
      ),
      DoodlePath(
        'M16.536 7.465a5 5 0 0 0-7.072 0l-2 2a5 5 0 0 0 0 7.07 5 5 0 0 0 7.072 0l2-2a5 5 0 0 0 0-7.07',
      ),
      DoodlePath(
        'M8 17v4a1 1 0 0 1-1.707.707 2.5 2.5 0 0 0-2.152-.717 1 1 0 0 1-1.131-1.131 2.5 2.5 0 0 0-.717-2.152A1 1 0 0 1 3 16h4',
      ),
    ]),
    Doodle([
      DoodlePath(
        'M18.6 14.4c.8-.8.8-2 0-2.8l-8.1-8.1a4.95 4.95 0 1 0-7.1 7.1l8.1 8.1c.9.7 2.1.7 2.9-.1Z',
      ),
      DoodlePath('m22 22-5.5-5.5'),
    ]),
    Doodle([
      DoodlePath('M11 17h.01'),
      DoodlePath(
        'M11.496 2c.324-.016.558.292.529.615a4 4 0 004.235 4.368.713.713 0 01.758.757 4 4 0 004.366 4.237c.323-.03.63.204.614.527a10 10 0 01-2.915 6.566A1 1 0 114.93 4.918 10 10 0 0111.496 2',
      ),
      DoodlePath('M12 12h.01'),
      DoodlePath('M16 16h.01'),
      DoodlePath('M16 3h.01'),
      DoodlePath('M21 4h.01'),
      DoodlePath('M21 8h.01'),
      DoodlePath('M7 14h.01'),
      DoodlePath('M9 8h.01'),
    ]),
    Doodle([
      DoodlePath(
        'M20.5 10a2.5 2.5 0 0 1-2.4-3H18a2.95 2.95 0 0 1-2.6-4.4 10 10 0 1 0 6.3 7.1c-.3.2-.8.3-1.2.3',
      ),
      DoodleCircle(12, 12, 3),
    ]),
    Doodle([
      DoodleCircle(11, 11, 8),
      DoodlePath('m21 21-4.3-4.3'),
      DoodlePath('M11 11a2 2 0 0 0 4 0 4 4 0 0 0-8 0 6 6 0 0 0 12 0'),
    ]),
    Doodle([
      DoodlePath(
        'M10.2 18H4.774a1.5 1.5 0 0 1-1.352-.97 11 11 0 0 1 .132-6.487',
      ),
      DoodlePath(
        'M18 10.2V4.774a1.5 1.5 0 0 0-.97-1.352 11 11 0 0 0-6.486.132',
      ),
      DoodlePath('M18 5a4 3 0 0 1 4 3 2 2 0 0 1-2 2 10 10 0 0 0-5.139 1.42'),
      DoodlePath('M5 18a3 4 0 0 0 3 4 2 2 0 0 0 2-2 10 10 0 0 1 1.42-5.14'),
      DoodlePath(
        'M8.709 2.554a10 10 0 0 0-6.155 6.155 1.5 1.5 0 0 0 .676 1.626l9.807 5.42a2 2 0 0 0 2.718-2.718l-5.42-9.807a1.5 1.5 0 0 0-1.626-.676',
      ),
    ]),
    Doodle([
      DoodlePath('M2 17a5 5 0 0 0 10 0c0-2.76-2.5-5-5-3-2.5-2-5 .24-5 3Z'),
      DoodlePath('M12 17a5 5 0 0 0 10 0c0-2.76-2.5-5-5-3-2.5-2-5 .24-5 3Z'),
      DoodlePath('M7 14c3.22-2.91 4.29-8.75 5-12 1.66 2.38 4.94 9 5 12'),
      DoodlePath('M22 9c-4.29 0-7.14-2.33-10-7 5.71 0 10 4.67 10 7Z'),
    ]),
    Doodle([
      DoodlePath(
        'M21.66 17.67a1.08 1.08 0 0 1-.04 1.6A12 12 0 0 1 4.73 2.38a1.1 1.1 0 0 1 1.61-.04z',
      ),
      DoodlePath('M19.65 15.66A8 8 0 0 1 8.35 4.34'),
      DoodlePath('m14 10-5.5 5.5'),
      DoodlePath('M14 17.85V10H6.15'),
    ]),
    Doodle([
      DoodlePath('M10 2v2'),
      DoodlePath('M14 2v2'),
      DoodlePath(
        'M16 8a1 1 0 0 1 1 1v8a4 4 0 0 1-4 4H7a4 4 0 0 1-4-4V9a1 1 0 0 1 1-1h14a4 4 0 1 1 0 8h-1',
      ),
      DoodlePath('M6 2v2'),
    ]),
    Doodle([
      DoodlePath(
        'M2 9.5a5.5 5.5 0 0 1 9.591-3.676.56.56 0 0 0 .818 0A5.49 5.49 0 0 1 22 9.5c0 2.29-1.5 4-3 5.5l-5.492 5.313a2 2 0 0 1-3 .019L5 15c-1.5-1.5-3-3.2-3-5.5',
      ),
    ]),
  ]),
  garden('Garden', [
    Doodle([
      DoodlePath(
        'M11 20a10 10 0 0010-10 25.9 25.9 0 00-1.04-7.281 1 1 0 00-1.755-.325C15.833 5.5 13 5.5 9.8 6.1A7 7 0 0011 20',
      ),
      DoodlePath('M2 21a5 5 0 012.911-4.544C7.613 15.212 8.351 15.24 11 13'),
    ]),
    Doodle([
      DoodleCircle(12, 12, 3),
      DoodlePath(
        'M12 16.5A4.5 4.5 0 1 1 7.5 12 4.5 4.5 0 1 1 12 7.5a4.5 4.5 0 1 1 4.5 4.5 4.5 4.5 0 1 1-4.5 4.5',
      ),
      DoodlePath('M12 7.5V9'),
      DoodlePath('M7.5 12H9'),
      DoodlePath('M16.5 12H15'),
      DoodlePath('M12 16.5V15'),
      DoodlePath('m8 8 1.88 1.88'),
      DoodlePath('M14.12 9.88 16 8'),
      DoodlePath('m8 16 1.88-1.88'),
      DoodlePath('M14.12 14.12 16 16'),
    ]),
    Doodle([
      DoodlePath(
        'M12 5a3 3 0 1 1 3 3m-3-3a3 3 0 1 0-3 3m3-3v1M9 8a3 3 0 1 0 3 3M9 8h1m5 0a3 3 0 1 1-3 3m3-3h-1m-2 3v-1',
      ),
      DoodleCircle(12, 8, 2),
      DoodlePath('M12 10v12'),
      DoodlePath('M12 22c4.2 0 7-1.667 7-5-4.2 0-7 1.667-7 5Z'),
      DoodlePath('M12 22c-4.2 0-7-1.667-7-5 4.2 0 7 1.667 7 5Z'),
    ]),
    Doodle([
      DoodlePath(
        'M14 9.536V7a4 4 0 0 1 4-4h1.5a.5.5 0 0 1 .5.5V5a4 4 0 0 1-4 4 4 4 0 0 0-4 4c0 2 1 3 1 5a5 5 0 0 1-1 3',
      ),
      DoodlePath('M4 9a5 5 0 0 1 8 4 5 5 0 0 1-8-4'),
      DoodlePath('M5 21h14'),
    ]),
    Doodle([
      DoodleCircle(12, 12, 4),
      DoodlePath('M12 2v2'),
      DoodlePath('M12 20v2'),
      DoodlePath('m4.93 4.93 1.41 1.41'),
      DoodlePath('m17.66 17.66 1.41 1.41'),
      DoodlePath('M2 12h2'),
      DoodlePath('M20 12h2'),
      DoodlePath('m6.34 17.66-1.41 1.41'),
      DoodlePath('m19.07 4.93-1.41 1.41'),
    ]),
    Doodle([
      DoodlePath('M2 17a5 5 0 0 0 10 0c0-2.76-2.5-5-5-3-2.5-2-5 .24-5 3Z'),
      DoodlePath('M12 17a5 5 0 0 0 10 0c0-2.76-2.5-5-5-3-2.5-2-5 .24-5 3Z'),
      DoodlePath('M7 14c3.22-2.91 4.29-8.75 5-12 1.66 2.38 4.94 9 5 12'),
      DoodlePath('M22 9c-4.29 0-7.14-2.33-10-7 5.71 0 10 4.67 10 7Z'),
    ]),
    Doodle([
      DoodlePath(
        'M10 10v.2A3 3 0 0 1 8.9 16H5a3 3 0 0 1-1-5.8V10a3 3 0 0 1 6 0Z',
      ),
      DoodlePath('M7 16v6'),
      DoodlePath('M13 19v3'),
      DoodlePath(
        'M12 19h8.3a1 1 0 0 0 .7-1.7L18 14h.3a1 1 0 0 0 .7-1.7L16 9h.2a1 1 0 0 0 .8-1.7L13 3l-1.4 1.5',
      ),
    ]),
    Doodle([
      DoodlePath('M12 20v-9'),
      DoodlePath('M14 7a4 4 0 0 1 4 4v3a6 6 0 0 1-12 0v-3a4 4 0 0 1 4-4z'),
      DoodlePath('M14.12 3.88 16 2'),
      DoodlePath('M21 21a4 4 0 0 0-3.81-4'),
      DoodlePath('M21 5a4 4 0 0 1-3.55 3.97'),
      DoodlePath('M22 13h-4'),
      DoodlePath('M3 21a4 4 0 0 1 3.81-4'),
      DoodlePath('M3 5a4 4 0 0 0 3.55 3.97'),
      DoodlePath('M6 13H2'),
      DoodlePath('m8 2 1.88 1.88'),
      DoodlePath('M9 7.13V6a3 3 0 1 1 6 0v1.13'),
    ]),
    Doodle([
      DoodlePath('M16.17 7.83 2 22'),
      DoodlePath(
        'M4.02 12a2.827 2.827 0 1 1 3.81-4.17A2.827 2.827 0 1 1 12 4.02a2.827 2.827 0 1 1 4.17 3.81A2.827 2.827 0 1 1 19.98 12a2.827 2.827 0 1 1-3.81 4.17A2.827 2.827 0 1 1 12 19.98a2.827 2.827 0 1 1-4.17-3.81A1 1 0 1 1 4 12',
      ),
      DoodlePath('m7.83 7.83 8.34 8.34'),
    ]),
    Doodle([
      DoodlePath('M2 13a6 6 0 1 0 12 0 4 4 0 1 0-8 0 2 2 0 0 0 4 0'),
      DoodleCircle(10, 13, 8),
      DoodlePath('M2 21h12c4.4 0 8-3.6 8-8V7a2 2 0 1 0-4 0v6'),
      DoodlePath('M18 3 19.1 5.2'),
      DoodlePath('M22 3 20.9 5.2'),
    ]),
    Doodle([
      DoodlePath(
        'M14.086 18.412A2 2 0 0112.67 19H5v-7.672a2 2 0 01.586-1.414L11.75 3.75a6 6 0 118.49 8.49z',
      ),
      DoodlePath('M16 8 2 22'),
      DoodlePath('M17.488 15H9'),
    ]),
  ]),
  space('Space', [
    Doodle([
      DoodlePath('M12 15v5s3.03-.55 4-2c1.08-1.62 0-5 0-5'),
      DoodlePath(
        'M4.5 16.5c-1.5 1.26-2 5-2 5s3.74-.5 5-2c.71-.84.7-2.13-.09-2.91a2.18 2.18 0 0 0-2.91-.09',
      ),
      DoodlePath(
        'M9 12a22 22 0 0 1 2-3.95A12.88 12.88 0 0 1 22 2c0 2.72-.78 7.5-6 11a22.4 22.4 0 0 1-4 2z',
      ),
      DoodlePath('M9 12H4s.55-3.03 2-4c1.62-1.08 5 .05 5 .05'),
    ]),
    Doodle([
      DoodlePath('M20.341 6.484A10 10 0 0 1 10.266 21.85'),
      DoodlePath('M3.659 17.516A10 10 0 0 1 13.74 2.152'),
      DoodleCircle(12, 12, 3),
      DoodleCircle(19, 5, 2),
      DoodleCircle(5, 19, 2),
    ]),
    Doodle([
      DoodlePath(
        'M20.985 12.486a9 9 0 1 1-9.473-9.472c.405-.022.617.46.402.803a6 6 0 0 0 8.268 8.268c.344-.215.825-.004.803.401',
      ),
    ]),
    Doodle([
      DoodlePath(
        'M11.525 2.295a.53.53 0 0 1 .95 0l2.31 4.679a2.123 2.123 0 0 0 1.595 1.16l5.166.756a.53.53 0 0 1 .294.904l-3.736 3.638a2.123 2.123 0 0 0-.611 1.878l.882 5.14a.53.53 0 0 1-.771.56l-4.618-2.428a2.122 2.122 0 0 0-1.973 0L6.396 21.01a.53.53 0 0 1-.77-.56l.881-5.139a2.122 2.122 0 0 0-.611-1.879L2.16 9.795a.53.53 0 0 1 .294-.906l5.165-.755a2.122 2.122 0 0 0 1.597-1.16z',
      ),
    ]),
    Doodle([
      DoodlePath(
        'M11.017 2.814a1 1 0 0 1 1.966 0l1.051 5.558a2 2 0 0 0 1.594 1.594l5.558 1.051a1 1 0 0 1 0 1.966l-5.558 1.051a2 2 0 0 0-1.594 1.594l-1.051 5.558a1 1 0 0 1-1.966 0l-1.051-5.558a2 2 0 0 0-1.594-1.594l-5.558-1.051a1 1 0 0 1 0-1.966l5.558-1.051a2 2 0 0 0 1.594-1.594z',
      ),
      DoodlePath('M20 2v4'),
      DoodlePath('M22 4h-4'),
      DoodleCircle(4, 20, 2),
    ]),
    Doodle([
      DoodlePath(
        'm13.5 6.5-3.148-3.148a1.205 1.205 0 0 0-1.704 0L6.352 5.648a1.205 1.205 0 0 0 0 1.704L9.5 10.5',
      ),
      DoodlePath('M16.5 7.5 19 5'),
      DoodlePath(
        'm17.5 10.5 3.148 3.148a1.205 1.205 0 0 1 0 1.704l-2.296 2.296a1.205 1.205 0 0 1-1.704 0L13.5 14.5',
      ),
      DoodlePath('M9 21a6 6 0 0 0-6-6'),
      DoodlePath(
        'M9.352 10.648a1.205 1.205 0 0 0 0 1.704l2.296 2.296a1.205 1.205 0 0 0 1.704 0l4.296-4.296a1.205 1.205 0 0 0 0-1.704l-2.296-2.296a1.205 1.205 0 0 0-1.704 0z',
      ),
    ]),
    Doodle([
      DoodlePath(
        'm10.065 12.493-6.18 1.318a.934.934 0 0 1-1.108-.702l-.537-2.15a1.07 1.07 0 0 1 .691-1.265l13.504-4.44',
      ),
      DoodlePath('m13.56 11.747 4.332-.924'),
      DoodlePath('m16 21-3.105-6.21'),
      DoodlePath(
        'M16.485 5.94a2 2 0 0 1 1.455-2.425l1.09-.272a1 1 0 0 1 1.212.727l1.515 6.06a1 1 0 0 1-.727 1.213l-1.09.272a2 2 0 0 1-2.425-1.455z',
      ),
      DoodlePath('m6.158 8.633 1.114 4.456'),
      DoodlePath('m8 21 3.105-6.21'),
      DoodleCircle(12, 13, 2),
    ]),
    Doodle([
      DoodlePath('M21.54 15H17a2 2 0 0 0-2 2v4.54'),
      DoodlePath(
        'M7 3.34V5a3 3 0 0 0 3 3a2 2 0 0 1 2 2c0 1.1.9 2 2 2a2 2 0 0 0 2-2c0-1.1.9-2 2-2h3.17',
      ),
      DoodlePath(
        'M11 21.95V18a2 2 0 0 0-2-2a2 2 0 0 1-2-2v-1a2 2 0 0 0-2-2H2.05',
      ),
      DoodleCircle(12, 12, 10),
    ]),
    Doodle([
      DoodlePath(
        'M11.017 2.814a1 1 0 0 1 1.966 0l1.051 5.558a2 2 0 0 0 1.594 1.594l5.558 1.051a1 1 0 0 1 0 1.966l-5.558 1.051a2 2 0 0 0-1.594 1.594l-1.051 5.558a1 1 0 0 1-1.966 0l-1.051-5.558a2 2 0 0 0-1.594-1.594l-5.558-1.051a1 1 0 0 1 0-1.966l5.558-1.051a2 2 0 0 0 1.594-1.594z',
      ),
    ]),
    Doodle([
      DoodlePath('M15 10v1'),
      DoodlePath(
        'M7.528 20.472a1.6 1.6 0 012.277 0l1.057 1.056a1.6 1.6 0 002.276 0l1.057-1.056a1.6 1.6 0 012.277 0l1.114 1.114a1.4 1.4 0 002.414-1V10a8 8 0 00-16 0v10.586a1.4 1.4 0 002.414 1z',
      ),
      DoodlePath('M9 10v1'),
    ]),
  ]),
  pets('Pets', [
    Doodle([
      DoodlePath(
        'M12 5c.67 0 1.35.09 2 .26 1.78-2 5.03-2.84 6.42-2.26 1.4.58-.42 7-.42 7 .57 1.07 1 2.24 1 3.44C21 17.9 16.97 21 12 21s-9-3-9-7.56c0-1.25.5-2.4 1-3.44 0 0-1.89-6.42-.5-7 1.39-.58 4.72.23 6.5 2.23A9.04 9.04 0 0 1 12 5Z',
      ),
      DoodlePath('M8 14v.5'),
      DoodlePath('M16 14v.5'),
      DoodlePath('M11.25 16.25h1.5L12 17l-.75-.75Z'),
    ]),
    Doodle([
      DoodlePath('M11.25 16.25h1.5L12 17z'),
      DoodlePath('M16 14v.5'),
      DoodlePath(
        'M4.42 11.247A13.152 13.152 0 0 0 4 14.556C4 18.728 7.582 21 12 21s8-2.272 8-6.444a11.702 11.702 0 0 0-.493-3.309',
      ),
      DoodlePath('M8 14v.5'),
      DoodlePath(
        'M8.5 8.5c-.384 1.05-1.083 2.028-2.344 2.5-1.931.722-3.576-.297-3.656-1-.113-.994 1.177-6.53 4-7 1.923-.321 3.651.845 3.651 2.235A7.497 7.497 0 0 1 14 5.277c0-1.39 1.844-2.598 3.767-2.277 2.823.47 4.113 6.006 4 7-.08.703-1.725 1.722-3.656 1-1.261-.472-1.855-1.45-2.239-2.5',
      ),
    ]),
    Doodle([
      DoodleCircle(11, 4, 2),
      DoodleCircle(18, 8, 2),
      DoodleCircle(20, 16, 2),
      DoodlePath(
        'M9 10a5 5 0 0 1 5 5v3.5a3.5 3.5 0 0 1-6.84 1.045Q6.52 17.48 4.46 16.84A3.5 3.5 0 0 1 5.5 10Z',
      ),
    ]),
    Doodle([
      DoodlePath(
        'M17 10c.7-.7 1.69 0 2.5 0a2.5 2.5 0 1 0 0-5 .5.5 0 0 1-.5-.5 2.5 2.5 0 1 0-5 0c0 .81.7 1.8 0 2.5l-7 7c-.7.7-1.69 0-2.5 0a2.5 2.5 0 0 0 0 5c.28 0 .5.22.5.5a2.5 2.5 0 1 0 5 0c0-.81-.7-1.8 0-2.5Z',
      ),
    ]),
    Doodle([
      DoodlePath(
        'M6.5 12c.94-3.46 4.94-6 8.5-6 3.56 0 6.06 2.54 7 6-.94 3.47-3.44 6-7 6s-7.56-2.53-8.5-6Z',
      ),
      DoodlePath('M18 12v.5'),
      DoodlePath('M16 17.93a9.77 9.77 0 0 1 0-11.86'),
      DoodlePath(
        'M7 10.67C7 8 5.58 5.97 2.73 5.5c-1 1.5-1 5 .23 6.5-1.24 1.5-1.24 5-.23 6.5C5.58 18.03 7 16 7 13.33',
      ),
      DoodlePath(
        'M10.46 7.26C10.2 5.88 9.17 4.24 8 3h5.8a2 2 0 0 1 1.98 1.67l.23 1.4',
      ),
      DoodlePath(
        'm16.01 17.93-.23 1.4A2 2 0 0 1 13.8 21H9.5a5.96 5.96 0 0 0 1.49-3.98',
      ),
    ]),
    Doodle([
      DoodlePath(
        'M2 9.5a5.5 5.5 0 0 1 9.591-3.676.56.56 0 0 0 .818 0A5.49 5.49 0 0 1 22 9.5c0 2.29-1.5 4-3 5.5l-5.492 5.313a2 2 0 0 1-3 .019L5 15c-1.5-1.5-3-3.2-3-5.5',
      ),
    ]),
    Doodle([
      DoodlePath('M16 7h.01'),
      DoodlePath('M3.4 18H12a8 8 0 0 0 8-8V7a4 4 0 0 0-7.28-2.3L2 20'),
      DoodlePath('m20 7 2 .5-2 .5'),
      DoodlePath('M10 18v3'),
      DoodlePath('M14 17.75V21'),
      DoodlePath('M7 18a6 6 0 0 0 3.84-10.61'),
    ]),
    Doodle([
      DoodlePath('M13 16a3 3 0 0 1 2.24 5'),
      DoodlePath('M18 12h.01'),
      DoodlePath(
        'M18 21h-8a4 4 0 0 1-4-4 7 7 0 0 1 7-7h.2L9.6 6.4a1 1 0 1 1 2.8-2.8L15.8 7h.2c3.3 0 6 2.7 6 6v1a2 2 0 0 1-2 2h-1a3 3 0 0 0-3 3',
      ),
      DoodlePath('M20 8.54V4a2 2 0 1 0-4 0v3'),
      DoodlePath('M7.612 12.524a3 3 0 1 0-1.6 4.3'),
    ]),
    Doodle([
      DoodlePath(
        'm12 10 2 4v3a1 1 0 0 0 1 1h2a1 1 0 0 0 1-1v-3a8 8 0 1 0-16 0v3a1 1 0 0 0 1 1h2a1 1 0 0 0 1-1v-3l2-4h4Z',
      ),
      DoodlePath('M4.82 7.9 8 10'),
      DoodlePath('M15.18 7.9 12 10'),
      DoodlePath('M16.93 10H20a2 2 0 0 1 0 4H2'),
    ]),
    Doodle([
      DoodlePath('M15.236 22a3 3 0 0 0-2.2-5'),
      DoodlePath('M16 20a3 3 0 0 1 3-3h1a2 2 0 0 0 2-2v-2a4 4 0 0 0-4-4V4'),
      DoodlePath('M18 13h.01'),
      DoodlePath(
        'M18 6a4 4 0 0 0-4 4 7 7 0 0 0-7 7c0-5 4-5 4-10.5a4.5 4.5 0 1 0-9 0 2.5 2.5 0 0 0 5 0C7 10 3 11 3 17c0 2.8 2.2 5 5 5h10',
      ),
    ]),
  ]),
  sea('Seaside', [
    Doodle([
      DoodlePath(
        'M14 11a2 2 0 1 1-4 0 4 4 0 0 1 8 0 6 6 0 0 1-12 0 8 8 0 0 1 16 0 10 10 0 1 1-20 0 11.93 11.93 0 0 1 2.42-7.22 2 2 0 1 1 3.16 2.44',
      ),
    ]),
    Doodle([
      DoodlePath('M2 12q2.5 2 5 0t5 0 5 0 5 0'),
      DoodlePath('M2 19q2.5 2 5 0t5 0 5 0 5 0'),
      DoodlePath('M2 5q2.5 2 5 0t5 0 5 0 5 0'),
    ]),
    Doodle([
      DoodlePath('M10 2v15'),
      DoodlePath(
        'M7 22a4 4 0 0 1-4-4 1 1 0 0 1 1-1h16a1 1 0 0 1 1 1 4 4 0 0 1-4 4z',
      ),
      DoodlePath(
        'M9.159 2.46a1 1 0 0 1 1.521-.193l9.977 8.98A1 1 0 0 1 20 13H4a1 1 0 0 1-.824-1.567z',
      ),
    ]),
    Doodle([
      DoodlePath('M12 6v16'),
      DoodlePath('m19 13 2-1a9 9 0 0 1-18 0l2 1'),
      DoodlePath('M9 11h6'),
      DoodleCircle(12, 4, 2),
    ]),
    Doodle([
      DoodlePath(
        'M6.5 12c.94-3.46 4.94-6 8.5-6 3.56 0 6.06 2.54 7 6-.94 3.47-3.44 6-7 6s-7.56-2.53-8.5-6Z',
      ),
      DoodlePath('M18 12v.5'),
      DoodlePath('M16 17.93a9.77 9.77 0 0 1 0-11.86'),
      DoodlePath(
        'M7 10.67C7 8 5.58 5.97 2.73 5.5c-1 1.5-1 5 .23 6.5-1.24 1.5-1.24 5-.23 6.5C5.58 18.03 7 16 7 13.33',
      ),
      DoodlePath(
        'M10.46 7.26C10.2 5.88 9.17 4.24 8 3h5.8a2 2 0 0 1 1.98 1.67l.23 1.4',
      ),
      DoodlePath(
        'm16.01 17.93-.23 1.4A2 2 0 0 1 13.8 21H9.5a5.96 5.96 0 0 0 1.49-3.98',
      ),
    ]),
    Doodle([
      DoodlePath('M13 8c0-2.76-2.46-5-5.5-5S2 5.24 2 8h2l1-1 1 1h4'),
      DoodlePath(
        'M13 7.14A5.82 5.82 0 0 1 16.5 6c3.04 0 5.5 2.24 5.5 5h-3l-1-1-1 1h-3',
      ),
      DoodlePath(
        'M5.89 9.71c-2.15 2.15-2.3 5.47-.35 7.43l4.24-4.25.7-.7.71-.71 2.12-2.12c-1.95-1.96-5.27-1.8-7.42.35',
      ),
      DoodlePath('M11 15.5c.5 2.5-.17 4.5-1 6.5h4c2-5.5-.5-12-1-14'),
    ]),
    Doodle([
      DoodleCircle(12, 12, 4),
      DoodlePath('M12 2v2'),
      DoodlePath('M12 20v2'),
      DoodlePath('m4.93 4.93 1.41 1.41'),
      DoodlePath('m17.66 17.66 1.41 1.41'),
      DoodlePath('M2 12h2'),
      DoodlePath('M20 12h2'),
      DoodlePath('m6.34 17.66-1.41 1.41'),
      DoodlePath('m19.07 4.93-1.41 1.41'),
    ]),
    Doodle([
      DoodlePath('M12 13v7a2 2 0 0 0 4 0'),
      DoodlePath('M12 2v2'),
      DoodlePath(
        'M20.992 13a1 1 0 0 0 .97-1.274 10.284 10.284 0 0 0-19.923 0A1 1 0 0 0 3 13z',
      ),
    ]),
    Doodle([DoodlePath('M17.5 19H9a7 7 0 1 1 6.71-9h1.79a4.5 4.5 0 1 1 0 9Z')]),
  ]),
  tech('Tech', [
    Doodle([
      DoodlePath('M12 8V4H8'),
      DoodleRect(4, 8, 16, 12, rx: 2, ry: 2),
      DoodlePath('M2 14h2'),
      DoodlePath('M20 14h2'),
      DoodlePath('M15 13v2'),
      DoodlePath('M9 13v2'),
    ]),
    Doodle([
      DoodleRect(2, 3, 20, 14, rx: 2, ry: 2),
      DoodleLine(8, 21, 16, 21),
      DoodleLine(12, 17, 12, 21),
    ]),
    Doodle([
      DoodlePath(
        'M18 5a2 2 0 0 1 2 2v8.526a2 2 0 0 0 .212.897l1.068 2.127a1 1 0 0 1-.9 1.45H3.62a1 1 0 0 1-.9-1.45l1.068-2.127A2 2 0 0 0 4 15.526V7a2 2 0 0 1 2-2z',
      ),
      DoodlePath('M20.054 15.987H3.946'),
    ]),
    Doodle([DoodlePath('M12 19h8'), DoodlePath('m4 17 6-6-6-6')]),
    Doodle([
      DoodlePath('M12 20v2'),
      DoodlePath('M12 2v2'),
      DoodlePath('M17 20v2'),
      DoodlePath('M17 2v2'),
      DoodlePath('M2 12h2'),
      DoodlePath('M2 17h2'),
      DoodlePath('M2 7h2'),
      DoodlePath('M20 12h2'),
      DoodlePath('M20 17h2'),
      DoodlePath('M20 7h2'),
      DoodlePath('M7 20v2'),
      DoodlePath('M7 2v2'),
      DoodleRect(4, 4, 16, 16, rx: 2, ry: 2),
      DoodleRect(8, 8, 8, 8, rx: 1, ry: 1),
    ]),
    Doodle([DoodlePath('m16 18 6-6-6-6'), DoodlePath('m8 6-6 6 6 6')]),
    Doodle([DoodlePath('M17.5 19H9a7 7 0 1 1 6.71-9h1.79a4.5 4.5 0 1 1 0 9Z')]),
    Doodle([
      DoodlePath(
        'M15.914 4a1.5 1.5 0 00-2.474-1.561l-9 9A1.5 1.5 0 005.5 14h4.002a.5.5 0 01.471.666L8.086 20a1.5 1.5 0 002.475 1.56l9-9A1.5 1.5 0 0018.5 10h-3.997a.5.5 0 01-.472-.667z',
      ),
    ]),
    Doodle([
      DoodlePath('M12 20h.01'),
      DoodlePath('M2 8.82a15 15 0 0 1 20 0'),
      DoodlePath('M5 12.859a10 10 0 0 1 14 0'),
      DoodlePath('M8.5 16.429a5 5 0 0 1 7 0'),
    ]),
    Doodle([
      DoodlePath(
        'M4.037 4.688a.495.495 0 0 1 .651-.651l16 6.5a.5.5 0 0 1-.063.947l-6.124 1.58a2 2 0 0 0-1.438 1.435l-1.579 6.126a.5.5 0 0 1-.947.063z',
      ),
    ]),
    Doodle([
      DoodlePath('M10 8h.01'),
      DoodlePath('M12 12h.01'),
      DoodlePath('M14 8h.01'),
      DoodlePath('M16 12h.01'),
      DoodlePath('M18 8h.01'),
      DoodlePath('M6 8h.01'),
      DoodlePath('M7 16h10'),
      DoodlePath('M8 12h.01'),
      DoodleRect(2, 4, 20, 16, rx: 2, ry: 2),
    ]),
    Doodle([
      DoodleRect(2, 2, 20, 8, rx: 2, ry: 2),
      DoodleRect(2, 14, 20, 8, rx: 2, ry: 2),
      DoodleLine(6, 6, 6.01, 6),
      DoodleLine(6, 18, 6.01, 18),
    ]),
  ]);

  const WallpaperPattern(this.label, this.drawings);
  final String label;

  /// The drawings scattered over the tile. (Not `doodles`: that is a pattern's name.)
  final List<Doodle> drawings;
}

/// Casama: Orchid, rose and periwinkle, from the Casama cloud.
const casamaScheme = FlexSchemeData(
  name: 'Casama',
  description: 'Orchid, rose and periwinkle, from the Casama cloud.',
  light: FlexSchemeColor(
    primary: Color(0xFF9C3A9E),
    primaryContainer: Color(0xFFFADDF5),
    secondary: Color(0xFFB8407F),
    secondaryContainer: Color(0xFFFFD9EA),
    tertiary: Color(0xFF5562CF),
    tertiaryContainer: Color(0xFFE0E2FF),
    appBarColor: Color(0xFFFCF3FB),
    error: Color(0xFFBA1A1A),
  ),
  dark: FlexSchemeColor(
    primary: Color(0xFFF2B0EC),
    primaryContainer: Color(0xFF6B1F69),
    secondary: Color(0xFFFFB1D4),
    secondaryContainer: Color(0xFF7A2152),
    tertiary: Color(0xFFBDC2FF),
    tertiaryContainer: Color(0xFF323C8A),
    appBarColor: Color(0xFF25102F),
    error: Color(0xFFFFB4AB),
  ),
);
