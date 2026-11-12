import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:casama_app/core/backend.dart';
import 'package:casama_app/core/providers.dart';
import 'package:casama_app/features/settings/about_you_screen.dart';
import 'package:casama_app/features/settings/me_avatar.dart';
import 'package:casama_app/features/settings/profile_photo.dart';
import 'package:casama_app/ui/person_avatar.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_test.dart' show harness, setSize;
import 'fake_backend.dart';

void main() {
  test(
    'a Google account without a photo gets its Google photo copied once',
    () async {
      final backend = FakeBackend()
        ..about = const AboutYouView(
          displayName: 'Robin Park',
          providerPhoto: true,
          photoImportTried: false,
        );
      final c = ProviderContainer(
        overrides: [backendProvider.overrideWithValue(backend)],
      );
      addTearDown(c.dispose);
      expect((await c.read(aboutYouProvider.future)).photoId, 'google-photo');

      // Removed on purpose: it doesn't come back by itself.
      await backend.removeProfilePhoto();
      c.invalidate(aboutYouProvider);
      expect((await c.read(aboutYouProvider.future)).photoId, isNull);
    },
  );

  testWidgets('the avatar shows the photo when there is one', (tester) async {
    final backend = FakeBackend()
      ..about = const AboutYouView(displayName: 'Robin Park', photoId: 'p1');
    await tester.pumpWidget(harness(backend, const Scaffold(body: MeAvatar())));
    await tester.pumpAndSettle();
    expect(
      tester.widget<PersonAvatar>(find.byType(PersonAvatar)).photoUrl,
      'http://localhost:8787/v1/photos/p1',
    );
  });

  testWidgets('About you offers the Google photo and removing it', (
    tester,
  ) async {
    await setSize(tester, const Size(900, 2600));
    final backend = FakeBackend()
      ..about = const AboutYouView(
        displayName: 'Robin Park',
        photoId: 'p1',
        providerPhoto: true,
      );
    await tester.pumpWidget(harness(backend, const AboutYouScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('profilePhoto')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('photoGallery')), findsOneWidget);
    expect(find.byKey(const Key('photoGoogle')), findsOneWidget);
    await tester.tap(find.byKey(const Key('photoRemove')));
    await tester.pumpAndSettle();
    expect(backend.about.photoId, isNull);

    // Nothing to remove now; the Google photo can come back on request.
    await tester.tap(find.byKey(const Key('profilePhoto')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('photoRemove')), findsNothing);
    await tester.tap(find.byKey(const Key('photoGoogle')));
    await tester.pumpAndSettle();
    expect(backend.about.photoId, 'google-photo');
  });

  test(
    'a small photo uploads as it is; anything else is redrawn as a square PNG',
    () async {
      final jpeg = Uint8List.fromList([0xff, 0xd8, 0xff, 0xe0, 1, 2, 3]);
      final small = await preparePhoto(jpeg);
      expect(small!.type, 'image/jpeg');
      expect(small.bytes, same(jpeg));
      expect(
        await preparePhoto(Uint8List.fromList('not a photo'.codeUnits)),
        isNull,
      );
    },
  );

  testWidgets('a big photo is cropped to the middle and shrunk', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final recorder = ui.PictureRecorder();
      Canvas(recorder).drawRect(
        const Rect.fromLTWH(0, 0, 800, 400),
        Paint()..color = const Color(0xFF3366FF),
      );
      final img = await recorder.endRecording().toImage(800, 400);
      final png = (await img.toByteData(format: ui.ImageByteFormat.png))!.buffer
          .asUint8List();
      final out = await preparePhoto(png, keepUnder: 10, side: 64);
      expect(out!.type, 'image/png');
      final back = await (await ui.instantiateImageCodec(out.bytes))
          .getNextFrame();
      expect((back.image.width, back.image.height), (64, 64));
    });
  });
}
