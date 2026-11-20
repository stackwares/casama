import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:casama/core/local_cache.dart';
import 'package:casama/core/providers.dart';
import 'package:casama/features/bots/bot_picture.dart' show readClipboardPicture;
import 'package:casama/features/workspaces/spaces.dart';
import 'package:casama/l10n/generated/app_localizations.dart';
import 'package:casama/ui/bot_avatar.dart' show BotPictureRef;
import 'package:casama_sdk/casama_sdk.dart' show BotPictureStyle, OrgRole;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'app_test.dart' show setSize;
import 'fake_backend.dart';

Future<Uint8List> _png(int side) async {
  final r = ui.PictureRecorder();
  ui.Canvas(r).drawRect(
    Rect.fromLTWH(0, 0, side.toDouble(), side.toDouble()),
    Paint()..color = const Color(0xFF4477EE),
  );
  final img = await r.endRecording().toImage(side, side);
  final d = await img.toByteData(format: ui.ImageByteFormat.png);
  return d!.buffer.asUint8List();
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Widget _settings(FakeBackend backend) => ProviderScope(
  overrides: [
    backendProvider.overrideWithValue(backend),
    localCacheProvider.overrideWithValue(const NoCache()),
  ],
  child: const MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: WorkspaceSettingsScreen(),
  ),
);

void main() {
  testWidgets('admin sees editable workspace avatar; member sees static avatar', (tester) async {
    await setSize(tester, const Size(800, 1200));
    final adminBackend = FakeBackend()..orgRole = OrgRole.admin;
    await tester.pumpWidget(_settings(adminBackend));
    await _settle(tester);
    expect(find.byKey(const Key('workspacePictureEdit')), findsOneWidget);

    final memberBackend = FakeBackend()..orgRole = OrgRole.member;
    await tester.pumpWidget(_settings(memberBackend));
    await _settle(tester);
    expect(find.byKey(const Key('workspacePictureEdit')), findsNothing);
  });

  testWidgets('recent picture switch and remove work from the workspace picture sheet', (
    tester,
  ) async {
    await setSize(tester, const Size(900, 1200));
    readClipboardPicture = () async => null;
    final backend = FakeBackend()..orgRole = OrgRole.owner;
    final bytes = (await tester.runAsync(() => _png(300)))!;
    await backend.setWorkspacePicture(orgId, bytes);
    final first = backend.workspaceAvatar!;
    await backend.setWorkspacePicture(orgId, bytes);
    expect(backend.workspaceAvatar, isNot(first));

    await tester.pumpWidget(_settings(backend));
    await _settle(tester);
    await tester.tap(find.byKey(const Key('workspacePictureEdit')));
    await _settle(tester);
    final id = BotPictureRef.parse(first)!.id;
    await tester.tap(find.byKey(Key('workspacePictureRecent-$id')));
    await _settle(tester);
    expect(backend.workspaceAvatar, first);

    await tester.tap(find.byKey(const Key('workspacePictureEdit')));
    await _settle(tester);
    await tester.tap(find.byKey(const Key('workspacePictureRemove')));
    await _settle(tester);
    expect(backend.workspaceAvatar, isNull);
  });

  testWidgets('AI draw dialog is compact and loads saved workspace candidates', (tester) async {
    await setSize(tester, const Size(1440, 1200));
    readClipboardPicture = () async => null;
    final backend = FakeBackend()..orgRole = OrgRole.owner;
    final drawn = await backend.drawWorkspacePictures(orgId, style: BotPictureStyle.flat);
    backend.workspaceOriginal = (await tester.runAsync(() => _png(300)))!;

    await tester.pumpWidget(_settings(backend));
    await _settle(tester);
    await tester.tap(find.byKey(const Key('workspacePictureEdit')));
    await _settle(tester);
    await tester.tap(find.byKey(const Key('workspacePictureDraw')));
    await _settle(tester);

    final dialogRect = tester.getRect(
      find.descendant(of: find.byType(Dialog), matching: find.byType(Material)).first,
    );
    expect(dialogRect.height, lessThan(760));

    final candFinder = find.byKey(Key('workspaceDrawn-${drawn.first.id}'));
    expect(candFinder, findsOneWidget);
    await tester.tap(candFinder);
    await _settle(tester);
    await tester.tap(find.byKey(const Key('avatarCropDone')));
    await _settle(tester);
    expect(backend.workspaceAvatar, drawn.first.avatarUrl);
  });
}
