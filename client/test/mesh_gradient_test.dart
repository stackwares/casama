import 'dart:ui' as ui;

import 'package:casama_app/core/backend.dart';
import 'package:casama_app/features/settings/gallery_previews.dart';
import 'package:casama_app/theme/mesh_gradient.dart';
import 'package:casama_app/theme/wallpaper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

int _channelGap(Color a, Color b) => [
  ((a.r - b.r) * 255).abs(),
  ((a.g - b.g) * 255).abs(),
  ((a.b - b.b) * 255).abs(),
].reduce((x, y) => x > y ? x : y).round();

void main() {
  // Theme and Flat take their colors from the color scheme, not from a mesh of their own.
  final meshes = WallpaperPalette.values.where(
    (p) => p != WallpaperPalette.theme && p != WallpaperPalette.flat,
  );

  test('every palette is a full 3×3 mesh whose corners and edges stay put', () {
    for (final p in meshes) {
      expect(p.light, hasLength(9), reason: p.name);
      expect(p.dark, hasLength(9), reason: p.name);
      expect(p.points, hasLength(9), reason: p.name);
      expect(p.points[0], Offset.zero, reason: p.name);
      expect(p.points[2], const Offset(1, 0), reason: p.name);
      expect(p.points[6], const Offset(0, 1), reason: p.name);
      expect(p.points[8], const Offset(1, 1), reason: p.name);
      expect(p.points[1].dy, 0, reason: p.name);
      expect(p.points[7].dy, 1, reason: p.name);
      expect(p.points[3].dx, 0, reason: p.name);
      expect(p.points[5].dx, 1, reason: p.name);
    }
  });

  test(
    'light meshes stay light and night meshes stay dark, so text reads on them',
    () {
      for (final p in meshes) {
        for (final c in p.light) {
          expect(c.computeLuminance(), greaterThan(0.55), reason: p.name);
        }
        for (final c in p.dark!) {
          expect(c.computeLuminance(), lessThan(0.05), reason: p.name);
        }
      }
    },
  );

  test('the theme palette builds nine colors from any scheme', () {
    for (final b in Brightness.values) {
      final scheme = ColorScheme.fromSeed(
        seedColor: Colors.teal,
        brightness: b,
      );
      expect(WallpaperPalette.theme.colorsFor(scheme), hasLength(9));
    }
  });

  test('the flat palette is just the surface color', () {
    for (final b in Brightness.values) {
      final scheme = ColorScheme.fromSeed(seedColor: Colors.teal, brightness: b);
      expect(WallpaperPalette.flat.colorsFor(scheme), List.filled(9, scheme.surface));
    }
  });

  test('the mesh passes through its control colors', () {
    final colors = WallpaperPalette.casama.light;
    for (var r = 0; r < 3; r++) {
      for (var c = 0; c < 3; c++) {
        final at = MeshGradient.colorAt(colors, c / 2, r / 2);
        expect(_channelGap(at, colors[r * 3 + c]), lessThanOrEqualTo(1));
      }
    }
  });

  test('painting fills the window with the mesh', () async {
    const size = Size(120, 200);
    final recorder = ui.PictureRecorder();
    final p = WallpaperPalette.sunset;
    MeshGradient.paint(Canvas(recorder), Offset.zero & size, p.light, p.points);
    final image = await recorder.endRecording().toImage(120, 200);
    final bytes = (await image.toByteData())!;
    Color pixel(int x, int y) {
      final i = (y * 120 + x) * 4;
      return Color.fromARGB(
        bytes.getUint8(i + 3),
        bytes.getUint8(i),
        bytes.getUint8(i + 1),
        bytes.getUint8(i + 2),
      );
    }

    expect(pixel(0, 0).a, 1);
    expect(_channelGap(pixel(0, 0), p.light[0]), lessThanOrEqualTo(6));
    expect(_channelGap(pixel(119, 199), p.light[8]), lessThanOrEqualTo(6));
    expect(pixel(60, 100).a, 1);
  });

  group('gallery meshes', () {
    final petal = <String, Object?>{
      'kind': 'mesh',
      'pattern': 'none',
      'palette': 'casama',
      'intensity': 0.5,
      'mesh': {
        'light': [
          '#FED1D6',
          '#FFDCCD',
          '#FFC7EB',
          '#F7DEFD',
          '#FFD6D2',
          '#E3D6FE',
          '#FEC4DE',
          '#DFE2FE',
          '#FFD6D7',
        ],
        'dark': [
          '#410918',
          '#481418',
          '#37082B',
          '#3B1F41',
          '#440D23',
          '#291544',
          '#350321',
          '#22224E',
          '#460D17',
        ],
        'points': [
          [0, 0],
          [0.42, 0],
          [1, 0],
          [0, 0.55],
          [0.6, 0.4],
          [1, 0.62],
          [0, 1],
          [0.58, 1],
          [1, 1],
        ],
      },
    };
    GalleryItem item(Map<String, Object?> doc) => GalleryItem(
      id: 'petal',
      type: 'wallpaper',
      name: 'Petal',
      authorName: 'Casama',
      license: 'CC0-1.0',
      document: doc,
    );

    test('a mesh wallpaper from the gallery draws its own colors', () {
      final spec = galleryWallpaperOf(item(petal))!;
      expect(spec.mesh, isNotNull);
      expect(spec.palette, WallpaperPalette.casama);
      final light = WallpaperTheme.of(spec, const ColorScheme.light());
      expect(light.colors.first, const Color(0xFFFED1D6));
      final dark = WallpaperTheme.of(spec, const ColorScheme.dark());
      expect(dark.colors.first, const Color(0xFF410918));
      expect(spec.points[4], const Offset(0.6, 0.4));
    });

    test('a broken or low-contrast mesh falls back to its palette', () {
      final mesh = petal['mesh']! as Map<String, Object?>;
      for (final bad in [
        {
          ...mesh,
          'light': ['#444444', ...(mesh['light']! as List).skip(1)],
        },
        {...mesh, 'dark': (mesh['dark']! as List).skip(1).toList()},
        {...mesh, 'points': 'everywhere'},
      ]) {
        final spec = galleryWallpaperOf(item({...petal, 'mesh': bad}))!;
        expect(spec.mesh, isNull);
        expect(spec.palette, WallpaperPalette.casama);
      }
    });

    test(
      'points are pinned to corners and edges and kept off the edges inside',
      () {
        final mesh = WallpaperMesh.fromJson({
          ...(petal['mesh']! as Map<String, Object?>),
          'points': [
            [0.3, 0.2],
            [0.95, 0.3],
            [0.5, 0.5],
            [0.4, 0.5],
            [0, 1],
            [0.2, 0.5],
            [0, 0],
            [0.5, 0],
            [0, 0],
          ],
        })!;
        expect(mesh.points, const [
          Offset.zero,
          Offset(0.8, 0),
          Offset(1, 0),
          Offset(0, 0.5),
          Offset(0.2, 0.8),
          Offset(1, 0.5),
          Offset(0, 1),
          Offset(0.5, 1),
          Offset(1, 1),
        ]);
      },
    );

    test('a mesh survives saving, compares by value and is replaced by picking a palette', () {
      final spec = galleryWallpaperOf(item(petal))!;
      final back = WallpaperSpec.fromJson(spec.toJson());
      expect(back, spec);
      expect(back.hashCode, spec.hashCode);
      expect(galleryWallpaperOf(item(petal)), spec);
      expect(spec.copyWith(intensity: 0.2).mesh, spec.mesh);
      expect(spec.copyWith(palette: WallpaperPalette.berry).mesh, isNull);
    });
  });
}
