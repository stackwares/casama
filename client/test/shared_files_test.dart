import 'package:flutter_test/flutter_test.dart';
import 'package:casama_app/features/chat/widgets/shared_files.dart';

void main() {
  test('files a reply links to on the computer become attachments; web links and repeats do not', () {
    final files = sharedFilesIn(
      'Here is [the report](workspace/bots/casama/report.md), the [chart](workspace/chart.png), '
      'the [same report](workspace/bots/casama/report.md) and [Google](https://google.com).',
    );
    expect(files.map((f) => f.path), ['bots/casama/report.md', 'chart.png']);
    expect(files.last.isImage, isTrue);
    expect(files.first.isImage, isFalse);
  });
}
