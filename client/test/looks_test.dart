import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:casama_app/core/backend.dart';
import 'package:casama_app/features/settings/gallery_previews.dart';
import 'package:casama_app/theme/schemes.dart';
import 'package:casama_app/theme/wallpaper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, Object?> _look(String path) =>
    (jsonDecode(File('looks/$path').readAsStringSync()) as Map)
        .cast<String, Object?>();

GalleryItem _item(
  String type,
  Map<String, Object?> doc, {
  List<String> requires = const [],
}) => GalleryItem(
  id: 'sample',
  type: type,
  name: 'Sample',
  authorName: 'Casama',
  license: 'CC0-1.0',
  document: doc,
  requires: requires,
);

const _star = [
  [
    'path',
    {'d': 'M12 2 15 9l7 1-5 5 1 7-6-3-6 3 1-7-5-5 7-1z'},
  ],
];

const _dot = [
  [
    'circle',
    {'cx': '12', 'cy': '12', 'r': 4},
  ],
  [
    'rect',
    {'x': 3, 'y': 3, 'width': 18, 'height': 18, 'rx': '2'},
  ],
  [
    'line',
    {'x1': 2, 'y1': 2, 'x2': 22, 'y2': 22},
  ],
  [
    'polyline',
    {'points': '3 6 9 12 15 6'},
  ],
  [
    'polygon',
    {'points': '12,2 22,22 2,22'},
  ],
  [
    'ellipse',
    {'cx': 12, 'cy': 12, 'rx': 10, 'ry': 6},
  ],
];

void main() {
  group('built-in looks come from client/looks', () {
    final index = _look('index.json');

    test('the palettes and patterns follow the data, in order', () {
      final meshes = (index['meshes']! as List).cast<String>();
      expect(WallpaperPalette.values.map((p) => p.name).toList(), [
        'theme',
        'flat',
        ...meshes,
      ]);
      for (final id in meshes) {
        final doc = _look('meshes/$id.json');
        final p = WallpaperPalette.values.byName(id);
        expect(p.label, doc['name']);
        expect(p.light.map(hexFromColor).toList(), [
          for (final c in doc['light']! as List) (c as String).toLowerCase(),
        ]);
        expect(p.dark!.map(hexFromColor).toList(), [
          for (final c in doc['dark']! as List) (c as String).toLowerCase(),
        ]);
      }
      final patterns = (index['patterns']! as List).cast<String>();
      expect(WallpaperPattern.values.map((p) => p.name).toList(), [
        'none',
        ...patterns,
      ]);
      for (final id in patterns) {
        final doc = _look('patterns/$id.json');
        final p = WallpaperPattern.values.byName(id);
        expect(p.label, doc['name']);
        expect(p.drawings, hasLength((doc['glyphs']! as List).length));
      }
    });

    test('the Casama scheme is the data', () {
      final doc = _look('schemes/casama.json');
      final light = doc['light']! as Map;
      final dark = doc['dark']! as Map;
      expect(
        hexFromColor(casamaScheme.light.primary),
        (light['primary'] as String).toLowerCase(),
      );
      expect(
        hexFromColor(casamaScheme.dark.tertiary),
        (dark['tertiary'] as String).toLowerCase(),
      );
      expect(
        hexFromColor(casamaScheme.light.appBarColor!),
        (light['appBar'] as String).toLowerCase(),
      );
    });
  });

  group('doodles', () {
    test('every shape parses, round-trips and stays on the 24-unit grid', () {
      for (final raw in [_star, _dot]) {
        final doodle = Doodle.fromJson(raw)!;
        expect(
          Doodle.fromJson(jsonDecode(jsonEncode(doodle.toJson()))),
          doodle,
        );
        final bounds = doodle.path.getBounds();
        expect(bounds.isEmpty, isFalse);
        expect(bounds.left, greaterThanOrEqualTo(-2));
        expect(bounds.right, lessThanOrEqualTo(26));
        expect(bounds.top, greaterThanOrEqualTo(-2));
        expect(bounds.bottom, lessThanOrEqualTo(26));
      }
    });

    test('every built-in drawing builds a path', () {
      for (final p in WallpaperPattern.values) {
        for (final d in p.drawings) {
          expect(d.path.getBounds().isEmpty, isFalse, reason: p.name);
        }
      }
    });

    test('broken doodles are refused', () {
      for (final bad in <Object?>[
        null,
        [],
        'M0 0',
        [
          [
            'script',
            {'src': 'x'},
          ],
        ],
        [
          [
            'path',
            {'d': 'M0 0 L url(x)'},
          ],
        ],
        [
          [
            'path',
            {'d': 'M0 0 L' * 400},
          ],
        ],
        [
          [
            'path',
            {'d': 'M 0 0 L 5'},
          ],
        ],
        [
          [
            'circle',
            {'cx': 12, 'cy': 12},
          ],
        ],
        [
          [
            'circle',
            {'cx': 40, 'cy': 12, 'r': 2},
          ],
        ],
        [
          [
            'rect',
            {'x': 0, 'y': 0, 'width': -3, 'height': 4},
          ],
        ],
        [
          [
            'polyline',
            {'points': '1 2 3'},
          ],
        ],
        List.filled(25, _star.first),
      ]) {
        expect(Doodle.fromJson(bad), isNull, reason: '$bad');
      }
      expect(Doodle.listFromJson(List.filled(25, _star)), isNull);
      expect(Doodle.listFromJson([_star, _dot]), hasLength(2));
    });
  });

  group('gallery drawings', () {
    final doc = <String, Object?>{
      'kind': 'pattern',
      'pattern': 'clouds',
      'palette': 'casama',
      'intensity': 0.5,
      'glyphs': ['star'],
      'doodles': [_star, _dot],
    };

    test('a wallpaper with doodles draws them, keeping its pattern as the fallback', () {
      final spec = galleryWallpaperOf(_item('wallpaper', doc))!;
      expect(spec.pattern, WallpaperPattern.clouds);
      expect(spec.doodles, hasLength(2));
      expect(spec.drawings, spec.doodles);
      final back = WallpaperSpec.fromJson(
        jsonDecode(jsonEncode(spec.toJson())) as Map<String, Object?>,
      );
      expect(back, spec);
      expect(back.hashCode, spec.hashCode);
      expect(spec.copyWith(intensity: 0.2).doodles, spec.doodles);
      expect(spec.copyWith(pattern: WallpaperPattern.tech).doodles, isNull);
      expect(
        spec.copyWith(clearDoodles: true).drawings,
        WallpaperPattern.clouds.drawings,
      );
    });

    test('broken doodles fall back to the pattern', () {
      final spec = galleryWallpaperOf(
        _item('wallpaper', {
          ...doc,
          'doodles': [
            [
              [
                'path',
                {'d': 'nope'},
              ],
            ],
          ],
        }),
      )!;
      expect(spec.doodles, isNull);
      expect(spec.drawings, WallpaperPattern.clouds.drawings);
    });

    test('a theme wallpaper can bring doodles too', () {
      final spec = galleryWallpaperOf(
        _item('theme', {
          'v': 2,
          'scheme': 'plum',
          'headingFont': 'Fraunces',
          'bodyFont': 'Figtree',
          'wallpaper': {
            'pattern': 'space',
            'palette': 'lavender',
            'intensity': 0.4,
            'doodles': [_dot],
          },
        }),
      )!;
      expect(spec.doodles, hasLength(1));
    });

    testWidgets('pattern tiles paint, built-in and own drawings alike', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(400, 200));
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final key = GlobalKey();
      final scheme = ColorScheme.fromSeed(seedColor: Colors.purple);
      const base = WallpaperSpec(
        pattern: WallpaperPattern.none,
        palette: WallpaperPalette.flat,
        intensity: 1,
      );
      final specs = [
        base,
        base.copyWith(pattern: WallpaperPattern.clouds),
        base.copyWith(doodles: Doodle.listFromJson([_star, _dot])),
      ];
      await tester.pumpWidget(
        MaterialApp(
          home: RepaintBoundary(
            key: key,
            child: Row(
              children: [
                for (final s in specs)
                  SizedBox(
                    width: 120,
                    height: 200,
                    child: Wallpaper(
                      force: true,
                      specOverride: WallpaperTheme.of(s, scheme),
                      child: const SizedBox.expand(),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final counts = await tester.runAsync(() async {
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = await boundary.toImage();
        final bytes = (await image.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        ))!;
        final surface = scheme.surface;
        int differing(int from) {
          var n = 0;
          for (var y = 0; y < 200; y++) {
            for (var x = from; x < from + 120; x++) {
              final i = (y * 400 + x) * 4;
              final r = bytes.getUint8(i);
              if ((r - (surface.r * 255).round()).abs() > 6) n++;
            }
          }
          return n;
        }

        return [differing(0), differing(120), differing(240)];
      });
      expect(counts![0], 0);
      expect(counts[1], greaterThan(100));
      expect(counts[2], greaterThan(100));
    });
  });

  group('full color schemes', () {
    Map<String, Object?> mode(
      String seed,
      String bg,
      String on,
      List<String> six,
    ) => {
      'seed': seed,
      'background': bg,
      'onBackground': on,
      for (var i = 0; i < 6; i++) schemeColorKeys[i]: six[i],
    };
    final doc = {
      'light': mode('#9C3A9E', '#FCF3FB', '#201A1E', [
        '#9C3A9E',
        '#FADDF5',
        '#B8407F',
        '#FFD9EA',
        '#5562CF',
        '#E0E2FF',
      ]),
      'dark': mode('#F2B0EC', '#211920', '#EBDFE6', [
        '#F2B0EC',
        '#6B1F69',
        '#FFB1D4',
        '#7A2152',
        '#BDC2FF',
        '#323C8A',
      ]),
    };

    test('a scheme with all six colors keeps them exactly', () {
      final choice = galleryChoiceOf(_item('scheme', doc))!;
      expect(choice.data.light.secondary, const Color(0xFFB8407F));
      expect(choice.data.dark.tertiaryContainer, const Color(0xFF323C8A));
      expect(choice.data.light.appBarColor, const Color(0xFFFADDF5));
    });

    test('a theme can carry a full scheme inline', () {
      final choice = galleryChoiceOf(
        _item('theme', {
          'v': 2,
          'scheme': doc,
          'headingFont': 'Fraunces',
          'bodyFont': 'Figtree',
        }),
      )!;
      expect(choice.data.light.tertiary, const Color(0xFF5562CF));
    });

    test('incomplete or broken colors fall back to the seeds', () {
      final light = {...doc['light']!}..remove('tertiary');
      final seeded = galleryChoiceOf(
        _item('scheme', {...doc, 'light': light}),
      )!;
      expect(seeded.data.light.primary, const Color(0xFF9C3A9E));
      expect(seeded.data.light.secondary, isNot(const Color(0xFFB8407F)));
      final bad = {...doc['dark']!, 'primary': 'pink'};
      expect(
        galleryChoiceOf(_item('scheme', {...doc, 'dark': bad}))!
            .data
            .dark
            .secondary,
        isNot(const Color(0xFFFFB1D4)),
      );
    });

    test('exact colors survive saving', () {
      final choice = galleryChoiceOf(_item('scheme', doc))!;
      final back = galleryChoiceFromColors(
        id: choice.id,
        name: choice.name,
        light: schemeColorsToJson(choice.data.light),
        dark: schemeColorsToJson(choice.data.dark),
      )!;
      expect(back.data.light.secondary, choice.data.light.secondary);
      expect(back.data.dark.appBarColor, choice.data.dark.appBarColor);
    });
  });

  test('items needing something this app can not draw are unsupported', () {
    expect(_item('wallpaper', {}).supported, isTrue);
    expect(
      _item(
        'wallpaper',
        {},
        requires: ['mesh', 'doodles', 'scheme-colors'],
      ).supported,
      isTrue,
    );
    expect(
      _item('wallpaper', {}, requires: ['mesh', 'holograms']).supported,
      isFalse,
    );
    final parsed = GalleryItem.fromJson({
      'id': 'x',
      'type': 'wallpaper',
      'name': 'X',
      'requires': ['animated-mesh'],
    });
    expect(parsed.requires, ['animated-mesh']);
    expect(parsed.supported, isFalse);
  });
}
