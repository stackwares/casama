import 'package:casama_computerd/computerd.dart';
import 'package:test/test.dart';

void main() {
  group('screenRecordingDenied (D-376)', () {
    test('reads agent-desktop 1.3.1 permissions output', () {
      const denied =
          '{"version":"2.6","ok":true,"command":"permissions","data":{"accessibility":{"state":"granted"},"automation":{"state":"unknown"},"screen_recording":{"state":"denied","suggestion":"Run agent-desktop permissions --guide."}}}';
      const granted =
          '{"version":"2.6","ok":true,"command":"permissions","data":{"accessibility":{"state":"granted"},"screen_recording":{"state":"granted"}}}';
      expect(screenRecordingDenied(denied), isTrue);
      expect(screenRecordingDenied('$denied\n'), isTrue);
      expect(screenRecordingDenied(granted), isFalse);
    });

    test('anything else is not a denial', () {
      expect(screenRecordingDenied(''), isFalse);
      expect(screenRecordingDenied('not json'), isFalse);
      expect(screenRecordingDenied('[]'), isFalse);
      expect(screenRecordingDenied('{"ok":false,"error":{"code":"PERM_DENIED"}}'), isFalse);
    });
  });
}
