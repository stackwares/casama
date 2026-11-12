import 'package:flutter_test/flutter_test.dart';
import 'package:casama_app/core/backend.dart';
import 'package:casama_app/features/chat/widgets/shared_files.dart';
import 'package:casama_app/l10n/generated/app_localizations_en.dart';
import 'package:casama_app/ui/tool_words.dart';

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

  test('a link to a file the reply already carries is not shown twice', () {
    final files = sharedFilesIn(
      'Saved as [clip](workspace/bots/casama/media/2026-11-12T02-12-02-424Z.mp4) and [notes](notes.md).',
      alreadyShown: const [
        AttachmentRef(
          path: 'media:85a81755',
          name: '2026-11-12T02-12-02-424Z.mp4',
          mimeType: 'video/mp4',
          size: 1,
        ),
      ],
    );
    expect(files.map((f) => f.path), ['notes.md']);
  });

  test('once files show as cards, the bubble drops the lines that only listed them', () {
    const text = 'Here it is, Oliver:\n\n'
        '📄 **PDF:** [dog-song-lyrics.pdf](workspace/dog-song-lyrics.pdf)\n\n'
        '- 📝 **Markdown:** [dog-song-lyrics.md](workspace/dog-song-lyrics.md)\n\n'
        'I also kept [the draft](workspace/draft.txt) and checked [Google](https://google.com).\n\n'
        '```\n[code](workspace/x.md)\n```';
    expect(
      textWithoutSharedLinks(text),
      'Here it is, Oliver:\n\n'
      'I also kept the draft and checked [Google](https://google.com).\n\n'
      '```\n[code](workspace/x.md)\n```',
    );
  });

  test('text without file links, or with nothing else, stays as it is', () {
    expect(textWithoutSharedLinks('See [Google](https://google.com).'), 'See [Google](https://google.com).');
    expect(textWithoutSharedLinks('[a.pdf](workspace/a.pdf)'), '[a.pdf](workspace/a.pdf)');
  });

  test('video generation reads as a video, not an image', () {
    final l10n = AppLocalizationsEn();
    expect(toolWords(l10n, 'media.video.generate').doing, 'Making a video');
    expect(toolWords(l10n, 'media__video__generate').done, 'Made a video');
    expect(toolWords(l10n, 'media.image.generate').doing, 'Making an image');
  });

  test('built-in tools have their own words; connected apps read by their name', () {
    final l10n = AppLocalizationsEn();
    expect(toolWords(l10n, 'bots.create').doing, 'Making a new bot');
    expect(toolWords(l10n, 'pages.list').doing, 'Checking your pages');
    expect(toolWords(l10n, 'desktop.files.search').doing, 'Searching files');
    expect(toolWords(l10n, 'composio.apps.googlecalendar_find_event').doing, 'Using Google Calendar');
    expect(toolWords(l10n, 'mcp.gmail.search_threads').doing, 'Using Gmail');
  });
}
