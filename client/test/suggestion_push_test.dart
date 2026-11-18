import 'package:casama/core/push.dart';
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
      expect(PushRegistrar.openTarget({'link': '//evil.example/x'}, null), isNull);
    });

    test('a bot chat link with no conversation opens the one the push is about', () {
      expect(PushRegistrar.openTarget({'link': '/bots/b/chat', 'conversation_id': 'c-1'}, null), '/bots/b/chat?c=c-1');
      expect(PushRegistrar.openTarget({'link': '/bots/b/chat?c=c-2', 'conversation_id': 'c-1'}, null), '/bots/b/chat?c=c-2');
      expect(PushRegistrar.openTarget({'link': '/approvals/a', 'conversation_id': 'c-1'}, null), '/approvals/a');
    });

    test('an approval asked in a chat opens that chat, with or without a button', () {
      final data = {'link': '/approvals/a', 'approval_id': 'a', 'bot_id': 'b', 'conversation_id': 'c-1'};
      expect(PushRegistrar.openTarget(data, null), '/bots/b/chat?c=c-1');
      expect(PushRegistrar.openTarget(data, 'approve'), '/bots/b/chat?c=c-1');
      expect(PushRegistrar.openTarget(data, 'deny'), '/bots/b/chat?c=c-1');
      // No chat (a routine): the approval screen.
      final routine = {'link': '/approvals/a', 'approval_id': 'a', 'bot_id': 'b'};
      expect(PushRegistrar.openTarget(routine, null), '/approvals/a');
      expect(PushRegistrar.openTarget(routine, 'approve'), '/approvals/a');
    });

    test('a push with no link opens the inbox', () {
      expect(PushRegistrar.openTarget({'notification_id': 'n-1'}, null), '/inbox');
    });
  });
}
