import 'package:flutter_test/flutter_test.dart';
import 'package:kasama_app/core/updater.dart';

void main() {
  test('a release is newer only when its version is higher', () {
    expect(isNewerVersion('0.9.0', '0.8.0'), isTrue);
    expect(isNewerVersion('0.8.1', '0.8.0'), isTrue);
    expect(isNewerVersion('1.0.0', '0.12.3'), isTrue);
    expect(isNewerVersion('0.8.0', '0.8.0'), isFalse);
    expect(isNewerVersion('0.8.0', '0.10.0'), isFalse);
    expect(isNewerVersion('0.8.0+9', '0.8.0'), isFalse); // build numbers aren't releases
  });

  test('updates come from the public releases repo, one feed per platform', () {
    expect(kUpdateFeedBase, 'https://github.com/stackwares/kasama-releases/releases/latest/download');
  });
}
