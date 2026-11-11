import 'package:casama_app/core/push.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the messaging worker address is at the site root and carries the Firebase app', () {
    final path = firebaseMessagingServiceWorkerPath(
      apiKey: 'key',
      appId: '1:278:web:abc',
      senderId: '278',
      projectId: 'kasama-ai',
      authDomain: 'kasama-ai.firebaseapp.com',
    );
    expect(path, startsWith('/firebase-messaging-sw.js?'));
    expect(path, contains('apiKey=key'));
    expect(path, contains('appId=1%3A278%3Aweb%3Aabc'));
    expect(path, contains('projectId=kasama-ai'));
    expect(path, contains('messagingSenderId=278'));
    expect(path, contains('authDomain=kasama-ai.firebaseapp.com'));
  });

  test('an empty auth domain is left off the worker address', () {
    final path = firebaseMessagingServiceWorkerPath(
      apiKey: 'key',
      appId: 'app',
      senderId: '1',
      projectId: 'p',
    );
    expect(path.contains('authDomain'), isFalse);
  });
}
