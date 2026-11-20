import 'package:casama/core/remote_content.dart';
import 'package:casama/features/chat/chat_screen.dart';
import 'package:casama/features/chat/widgets/intro_video.dart';
import 'package:casama_sdk/casama_sdk.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  test('upright phones get the vertical cut; remote links replace both', () {
    expect(introVideoUri(const Size(390, 844)).toString(), kIntroVideoVerticalUrl);
    expect(introVideoUri(const Size(1280, 800)).toString(), kIntroVideoUrl);
    applyRemoteContent(RemoteAppConfig.fromJson({
      'min_versions': <String, dynamic>{},
      'update_urls': <String, dynamic>{},
      'maintenance': null,
      'announcements': <dynamic>[],
      'flags': <String, dynamic>{},
      'links': {
        'intro_video': 'https://www.youtube.com/watch?v=new16x9',
        'intro_video_vertical': 'https://www.youtube.com/shorts/new9x16',
      },
    }));
    expect(introVideoUri(const Size(390, 844)).toString(), 'https://www.youtube.com/shorts/new9x16');
    expect(introVideoUri(const Size(1280, 800)).toString(), 'https://www.youtube.com/watch?v=new16x9');
  });
}
