import 'package:casama_app/core/push.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('push open target (D-247)', () {
    test('"Do it" on a suggestion accepts it, with the bot for the chat', () {
      expect(PushRegistrar.openTarget({'suggestion_id': 's-1', 'bot_id': 'b-1', 'link': '/inbox'}, 'accept'), '/suggestions/s-1/accept?bot=b-1');
      expect(PushRegistrar.openTarget({'suggestion_id': 's-1', 'link': '/inbox'}, 'accept'), '/suggestions/s-1/accept');
    });

    test('a plain tap follows the link; other pushes are unchanged', () {
      expect(PushRegistrar.openTarget({'suggestion_id': 's-1', 'link': '/inbox'}, null), '/inbox');
      expect(PushRegistrar.openTarget({'link': '/bots/b/chat'}, 'accept'), '/bots/b/chat');
      expect(PushRegistrar.openTarget({'link': 'https://evil.example'}, null), isNull);
    });
  });
}
