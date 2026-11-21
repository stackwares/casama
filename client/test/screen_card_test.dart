// The bot's screen in a floating card (SCREEN-CARD-PLAN): the tile's states, its size, and the
// corner it snaps to and remembers.
import 'package:casama/l10n/generated/app_localizations.dart';
import 'package:casama/features/chat/widgets/screen_card.dart';
import 'package:casama/theme/app_theme.dart';
import 'package:casama/ui/screen_tile.dart';
import 'package:casama/ui/shell_layout.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _host(Widget child, {bool dark = false}) => ProviderScope(
  child: MaterialApp(
    theme: dark ? AppTheme.dark() : AppTheme.light(),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  ),
);

Widget _tile(ScreenTileState state, {String? heldBy, VoidCallback? onTap, VoidCallback? onClose}) => Center(
  child: SizedBox(
    width: 160,
    child: ScreenTile(
      picture: const ColoredBox(color: Colors.white),
      state: state,
      botName: 'Ava',
      heldBy: heldBy,
      onTap: onTap ?? () {},
      onClose: onClose ?? () {},
    ),
  ),
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('each state shows its label, and only those that need one', (tester) async {
    for (final dark in [false, true]) {
      await tester.pumpWidget(_host(_tile(ScreenTileState.watching), dark: dark));
      expect(find.text('Needs you'), findsNothing);
      expect(find.text('Done'), findsNothing);
      expect(find.bySemanticsLabel("Ava's screen, live"), findsOneWidget);

      await tester.pumpWidget(_host(_tile(ScreenTileState.needsYou), dark: dark));
      expect(find.text('Needs you'), findsOneWidget);

      await tester.pumpWidget(_host(_tile(ScreenTileState.held), dark: dark));
      expect(find.text('You have the screen'), findsOneWidget);

      await tester.pumpWidget(_host(_tile(ScreenTileState.held, heldBy: 'Mia'), dark: dark));
      expect(find.text('Mia has the screen'), findsOneWidget);

      await tester.pumpWidget(_host(_tile(ScreenTileState.done), dark: dark));
      expect(find.text('Done'), findsOneWidget);

      await tester.pumpWidget(_host(_tile(ScreenTileState.stale), dark: dark));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    }
  });

  testWidgets('tap opens, close hides', (tester) async {
    var taps = 0, closes = 0;
    await tester.pumpWidget(_host(_tile(ScreenTileState.watching, onTap: () => taps++, onClose: () => closes++)));
    await tester.tap(find.byKey(const Key('screenTile')));
    await tester.tap(find.byKey(const Key('screenTileClose')));
    expect((taps, closes), (1, 1));
  });

  test('width: 38% of a phone chat within 132–168, 220 on tablets', () {
    expect(screenCardWidth(320, LayoutSize.phone), 132);
    expect(screenCardWidth(393, LayoutSize.phone), closeTo(149.3, 0.1));
    expect(screenCardWidth(500, LayoutSize.phone), 168);
    expect(screenCardWidth(800, LayoutSize.tablet), 220);
  });

  testWidgets('starts top right, snaps to the nearest corner and remembers it', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    Widget corner() => _host(
      ScreenTileCorner(
        width: 150,
        child: ScreenTile(picture: null, state: ScreenTileState.watching, botName: 'Ava', onTap: () {}, onClose: () {}),
      ),
    );
    await tester.pumpWidget(corner());
    await tester.pumpAndSettle();
    final start = tester.getTopLeft(find.byKey(const Key('screenTile')));
    expect(start.dx, greaterThan(200));
    expect(start.dy, lessThan(100));

    // Dragged down and to the left: it settles in the bottom-left corner.
    await tester.drag(find.byKey(const Key('screenTile')), const Offset(-220, 450));
    await tester.pumpAndSettle();
    final end = tester.getTopLeft(find.byKey(const Key('screenTile')));
    expect(end.dx, lessThan(50));
    expect(end.dy, greaterThan(400));
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('screenCard.corner'), '-1,1');

    // A new card (another chat, the next launch) starts where it was left.
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(corner());
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.byKey(const Key('screenTile'))).dx, lessThan(50));
  });

  testWidgets('touches outside the card reach what is under it', (tester) async {
    var under = 0;
    await tester.pumpWidget(
      _host(
        Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: () => under++,
                child: const ColoredBox(color: Colors.transparent),
              ),
            ),
            Positioned.fill(
              child: ScreenTileCorner(
                width: 150,
                child: ScreenTile(picture: null, state: ScreenTileState.watching, botName: 'Ava', onTap: () {}, onClose: () {}),
              ),
            ),
          ],
        ),
      ),
    );
    await tester.tapAt(const Offset(40, 500));
    expect(under, 1);
  });
}
