import 'package:casama/core/remote_content.dart';
import 'package:casama/features/chat/chat_screen.dart';
import 'package:casama/features/chat/widgets/intro_video.dart';
import 'package:casama/l10n/generated/app_localizations.dart';
import 'package:casama_sdk/casama_sdk.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';

import 'app_test.dart' show harness, setSize;
import 'fake_backend.dart';

/// The intro film row in an empty chat, and its remote links.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    RemoteContent.reset();
  });

  testWidgets('a new person sees the film row, and closing it keeps it closed', (tester) async {
    await setSize(tester, const Size(600, 900));
    await tester.pumpWidget(harness(FakeBackend(), const ChatScreen(botId: botId)));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('introVideo')), findsOneWidget);
    await tester.tap(find.byKey(const Key('dismissIntroVideo')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('introVideo')), findsNothing);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('introVideo.done'), isTrue);
  });

  testWidgets('no row once it was watched or closed before', (tester) async {
    SharedPreferences.setMockInitialValues({'introVideo.done': true});
    await setSize(tester, const Size(600, 900));
    await tester.pumpWidget(harness(FakeBackend(), const ChatScreen(botId: botId)));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('introVideo')), findsNothing);
  });

  RemoteAppConfig config(Map<String, String> links) => RemoteAppConfig.fromJson({
        'min_versions': <String, dynamic>{},
        'update_urls': <String, dynamic>{},
        'maintenance': null,
        'announcements': <dynamic>[],
        'flags': <String, dynamic>{},
        'links': links,
      });
  const phone = Size(390, 844), desktop = Size(1280, 800);

  test('upright phones get the 9:16 film and Short; everything else 16:9', () {
    expect(introFilmUri(phone).toString(), kIntroFilmVerticalUrl);
    expect(introFilmUri(desktop).toString(), kIntroFilmUrl);
    expect(introFilmUri(const Size(844, 390)).toString(), kIntroFilmUrl); // a phone held sideways
    expect(introFilmUri(const Size(820, 1180)).toString(), kIntroFilmUrl); // a tablet
    expect(introYoutubeUri(phone).toString(), kIntroYoutubeVerticalUrl);
    expect(introYoutubeUri(desktop).toString(), kIntroYoutubeUrl);
  });

  test('remote links replace every address', () {
    applyRemoteContent(config({
      'intro_video': 'https://cdn.example.com/film-v9.mp4',
      'intro_video_vertical': 'https://cdn.example.com/film-v9-tall.mp4',
      'intro_video_youtube': 'https://www.youtube.com/watch?v=new16x9',
      'intro_video_youtube_vertical': 'https://www.youtube.com/shorts/new9x16',
    }));
    expect(introFilmUri(phone).toString(), 'https://cdn.example.com/film-v9-tall.mp4');
    expect(introFilmUri(desktop).toString(), 'https://cdn.example.com/film-v9.mp4');
    expect(introYoutubeUri(phone).toString(), 'https://www.youtube.com/shorts/new9x16');
    expect(introYoutubeUri(desktop).toString(), 'https://www.youtube.com/watch?v=new16x9');
  });

  test('only the 16:9 link set: phones use it too, not the old built-in cut', () {
    applyRemoteContent(config({
      'intro_video': 'https://cdn.example.com/film-v9.mp4',
      'intro_video_youtube': 'https://www.youtube.com/watch?v=new16x9',
    }));
    expect(introFilmUri(phone).toString(), 'https://cdn.example.com/film-v9.mp4');
    expect(introYoutubeUri(phone).toString(), 'https://www.youtube.com/watch?v=new16x9');
  });

  test('a link that is not https is ignored and the built-in film stays', () {
    applyRemoteContent(config({'intro_video': 'http://cdn.example.com/film.mp4'}));
    expect(introFilmUri(desktop).toString(), kIntroFilmUrl);
  });

  test('video files play in the app; pages and Windows/Linux go to the browser', () {
    bool inApp(String url, {bool player = true}) => introPlaysInApp(Uri.parse(url), playerAvailable: player);
    expect(inApp(kIntroFilmUrl), isTrue);
    expect(inApp('https://cdn.example.com/a/film.MOV'), isTrue);
    expect(inApp('https://cdn.example.com/live/index.m3u8'), isTrue);
    expect(inApp('https://cdn.example.com/film.webm?v=2'), isTrue);
    expect(inApp('https://www.youtube.com/watch?v=cype-154_p0'), isFalse);
    expect(inApp('https://youtu.be/cype-154_p0'), isFalse);
    expect(inApp('https://casama.ai/#film'), isFalse);
    expect(inApp(kIntroFilmUrl, player: false), isFalse);
  });

  testWidgets('a film that cannot load shows Try again and Watch on YouTube, not a blank screen', (tester) async {
    await setSize(tester, phone);
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: IntroFilmPlayer(
        film: Uri.parse(kIntroFilmUrl),
        youtube: Uri.parse(kIntroYoutubeUrl),
        controllerFor: (film) => _Offline(film),
      ),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const Key('introFilmFailed')), findsOneWidget);
    expect(find.byKey(const Key('introFilmRetry')), findsOneWidget);
    expect(find.byKey(const Key('introFilmYoutube')), findsOneWidget);
    expect(find.byKey(const Key('introFilmClose')), findsOneWidget);
  });

  testWidgets('a film that never started keeps the empty-chat row', (tester) async {
    await setSize(tester, const Size(600, 900));
    await tester.pumpWidget(harness(FakeBackend(), const ChatScreen(botId: botId)));
    await tester.pumpAndSettle();
    // Under flutter test there's no player or browser, so the film can't start.
    await tester.tap(find.byKey(const Key('introVideo')));
    await tester.pumpAndSettle();
    if (find.byKey(const Key('introFilmClose')).evaluate().isNotEmpty) {
      await tester.tap(find.byKey(const Key('introFilmClose')));
      await tester.pumpAndSettle();
    }
    expect(find.byKey(const Key('introVideo')), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('introVideo.done'), isNull);
  });
}

/// A player that fails to load, the way it does offline.
class _Offline extends VideoPlayerController {
  _Offline(super.dataSource) : super.networkUrl();

  @override
  Future<void> initialize() async => throw Exception('offline');

  @override
  // ignore: must_call_super
  Future<void> dispose() async {}
}
