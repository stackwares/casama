import 'package:flutter_test/flutter_test.dart';
import 'package:casama/core/updater.dart';

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
    expect(kUpdateFeedBase, 'https://raw.githubusercontent.com/stackwares/casama-releases/main');
  });

  test('the Linux notice skips CLI releases, drafts and prereleases', () {
    final releases = [
      {'tag_name': 'cli-v0.1.1'},
      {'tag_name': 'v0.3.0', 'draft': true},
      {'tag_name': 'v0.2.1', 'prerelease': true},
      {'tag_name': 'v0.2.0'},
    ];
    expect(latestDesktopRelease(releases)?['tag_name'], 'v0.2.0');
    expect(latestDesktopRelease([{'tag_name': 'cli-v0.1.1'}]), isNull);
  });
}
