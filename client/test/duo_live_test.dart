// The bot's computer on a folding phone, partly folded (D-411): its screen on one side of the
// fold, a trackpad and the controls on the other.
import 'package:casama/core/fold/fold.dart';
import 'package:casama/core/live.dart';
import 'package:casama/core/providers.dart';
import 'package:casama/features/app_lock/app_lock.dart';
import 'package:casama/features/computer/live_view_screen.dart';
import 'package:casama/l10n/generated/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'fake_backend.dart';
import 'fake_live.dart';
import 'fake_unlockers.dart';
import 'support/poses.dart';

final _iphone = TargetPlatformVariant.only(TargetPlatform.iOS);

Future<FakeLiveConnector> _pump(WidgetTester tester, DuoPose pose) async {
  setPose(tester, pose);
  final live = FakeLiveConnector();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        backendProvider.overrideWithValue(FakeBackend()),
        unlockersProvider.overrideWithValue(FakeUnlockers()),
        liveConnectorProvider.overrideWithValue(live),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => FoldScope(child: child!),
        home: const LiveViewScreen(computerId: computerId),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  return live;
}

int _x(List<int> move) => (move[3] << 8) | move[4];
int _y(List<int> move) => (move[5] << 8) | move[6];

void main() {
  testWidgets(
    'laptop: the screen above the fold, the trackpad below it, and the trackpad drives the pointer',
    (tester) async {
      final live = await _pump(tester, DuoPose.laptop);
      final surface = tester.getRect(find.byKey(const Key('liveSurface')));
      final pad = tester.getRect(find.byKey(const Key('liveTrackpad')));
      expect(surface.top, greaterThanOrEqualTo(82));
      expect(surface.bottom, lessThanOrEqualTo(455.5));
      expect(pad.top, greaterThanOrEqualTo(495.5));
      // Watching: the trackpad waits for Take Control.
      expect(find.text('Take control to use the trackpad.'), findsOneWidget);

      await tester.tap(find.byKey(const Key('takeControl')));
      await tester.pump();
      await tester.pump();
      await tester.pump();
      live.connection.sent.clear();

      // One finger moves the pointer from the middle of the computer's screen.
      await tester.drag(
        find.byKey(const Key('liveTrackpad')),
        const Offset(50, 0),
      );
      await tester.pump();
      final moves = live.connection.sent
          .where((f) => f[0] == NekoInput.opMove)
          .toList();
      expect(moves, isNotEmpty);
      expect(_x(moves.last), greaterThan(640));
      expect(_y(moves.last), closeTo(400, 30));

      // A tap clicks where the pointer is.
      live.connection.sent.clear();
      await tester.tap(find.byKey(const Key('liveTrackpad')));
      await tester.pump();
      expect(
        live.connection.sent.map((f) => f[0]),
        containsAllInOrder([
          NekoInput.opMove,
          NekoInput.opButtonDown,
          NekoInput.opButtonUp,
        ]),
      );

      // Two fingers scroll.
      live.connection.sent.clear();
      final center = tester.getCenter(find.byKey(const Key('liveTrackpad')));
      final a = await tester.startGesture(
        center - const Offset(20, 0),
        pointer: 7,
      );
      final b = await tester.startGesture(
        center + const Offset(20, 0),
        pointer: 8,
      );
      for (var i = 0; i < 6; i++) {
        await a.moveBy(const Offset(0, -15));
        await b.moveBy(const Offset(0, -15));
        await tester.pump();
      }
      await a.up();
      await b.up();
      await tester.pump();
      expect(
        live.connection.sent.where((f) => f[0] == NekoInput.opScroll),
        isNotEmpty,
      );
      await tester.pumpWidget(const SizedBox());
    },
    variant: _iphone,
  );

  testWidgets(
    'book: the screen on the left of the fold, the controls on the right',
    (tester) async {
      await _pump(tester, DuoPose.book);
      final surface = tester.getRect(find.byKey(const Key('liveSurface')));
      final pad = tester.getRect(find.byKey(const Key('liveTrackpad')));
      expect(surface.right, lessThanOrEqualTo(455.5));
      expect(pad.left, greaterThanOrEqualTo(495.5));
      expect(
        tester.getRect(find.byKey(const Key('takeControl'))).left,
        greaterThanOrEqualTo(495.5),
      );
      await tester.pumpWidget(const SizedBox());
    },
    variant: _iphone,
  );

  testWidgets(
    'lying flat there is no trackpad: the screen is touched directly, as on any phone',
    (tester) async {
      await _pump(tester, DuoPose.openTall);
      expect(find.byKey(const Key('liveTrackpad')), findsNothing);
      expect(find.byKey(const Key('liveSurface')), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
    variant: _iphone,
  );
}
