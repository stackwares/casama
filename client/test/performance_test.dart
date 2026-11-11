// Guards for the performance work: cached Markdown blocks render exactly what a whole parse would,
// themes are reused instead of rebuilt, thumbnails decode small, settled entrances add no layer,
// and a streamed word rebuilds only its own chat row.
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:casama_app/core/backend.dart';
import 'package:casama_app/core/local_cache.dart';
import 'package:casama_app/core/providers.dart';
import 'package:casama_app/features/chat/chat_screen.dart';
import 'package:casama_app/features/chat/widgets/chat_markdown.dart';
import 'package:casama_app/features/chat/widgets/chat_widgets.dart';
import 'package:casama_app/features/chat/widgets/composer.dart';
import 'package:casama_app/l10n/generated/app_localizations.dart';
import 'package:casama_app/theme/app_theme.dart';
import 'package:casama_app/theme/appearance.dart';
import 'package:casama_app/theme/wallpaper.dart';
import 'package:casama_app/ui/cover_image.dart';
import 'package:casama_app/ui/motion.dart';
import 'package:casama_app/ui/shell_header.dart';
import 'package:markdown_widget/markdown_widget.dart';

import 'fake_backend.dart';

/// Long enough that [markdownChunks] splits it.
final _lead = '${'Some words to start the reply with. ' * 14}\n\n';

String _plain(Widget w) {
  final text = (w as Padding).child! as Text;
  return text.textSpan!.toPlainText();
}

List<String> _blocks(String text) => [for (final w in MarkdownGenerator().buildWidgets(text)) _plain(w)];

void main() {
  group('markdownChunks', () {
    final samples = <String, String>{
      'mixed reply': '## Findings\n\nRevenue grew **12%**.\n\n- one\n- two\n\n1. first\n2. second\n\n```python\nprint(1)\n\nprint(2)\n```\n\n| a | b |\n| - | - |\n| 1 | 2 |\n\n> quoted\n\nThe end.',
      'loose ordered list': '1. alpha\n\n2. beta\n\n3. gamma\n\nAfter the list.',
      'list continuations': '- a\n\n  more about a\n\n- b\n\n      code in b\n\nend of list',
      'fence with blank lines': '```\nline\n\n# not a heading\n\n- not a list\n```\n\nafter the fence',
      'long and tilde fences': '````\n```\ninner\n\n```\n````\n\n~~~\ntilde\n\nfence\n~~~\n\ntext',
      'quotes': '> first\n\n> second\n\nparagraph',
      'indented code': 'para\n\n    code\n\n    more code\n\nafter',
      'unclosed fence while streaming': 'text\n\n```py\nx = 1\n\ny = 2',
      'setext headings': 'Title\n=====\n\npara\n\nSub\n---\n\nend',
      'nested list': '- outer\n\n  - inner\n\n    inner more\n\n- outer two\n\nclosing',
      'crlf': 'one\r\n\r\ntwo\r\n\r\n- three\r\n\r\nfour',
    };
    for (final MapEntry(key: name, value: body) in samples.entries) {
      test('parses the same in runs as whole: $name', () {
        final text = '$_lead$body';
        final chunks = markdownChunks(text);
        expect(chunks.join(), text);
        expect([for (final c in chunks) ..._blocks(c)], _blocks(text));
      });
    }

    test('splits long replies but keeps short ones and risky ones whole', () {
      expect(markdownChunks('$_lead${'para\n\n' * 5}').length, greaterThan(3));
      expect(markdownChunks('short\n\ntext'), ['short\n\ntext']);
      final withRef = '$_lead[docs][1]\n\nmore\n\n[1]: https://example.com';
      expect(markdownChunks(withRef), [withRef]);
      final withHtml = '$_lead<div>\n\nhi\n\n</div>';
      expect(markdownChunks(withHtml), [withHtml]);
    });

    test('a streaming reply only changes its last run', () {
      final text = '$_lead${'Paragraph number one.\n\n' * 6}Still typ';
      final before = markdownChunks(text);
      final after = markdownChunks('${text}ing more words');
      expect(after.length, before.length);
      expect(after.sublist(0, after.length - 1), before.sublist(0, before.length - 1));
    });
  });

  testWidgets('ChatMarkdown keeps finished blocks when the text grows', (tester) async {
    Widget app(String data) => MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(
        body: SingleChildScrollView(child: ChatMarkdown(data: data, selectable: false)),
      ),
    );
    final first = '$_lead${'A finished paragraph.\n\n' * 4}';
    await tester.pumpWidget(app(first));
    final column = tester.widget<Column>(find.descendant(of: find.byType(ChatMarkdown), matching: find.byType(Column)).first);
    final firstBlocks = [...column.children];

    // Same text: the very same subtree, so Flutter skips it.
    await tester.pumpWidget(app(first));
    expect(identical(tester.widget<Column>(find.descendant(of: find.byType(ChatMarkdown), matching: find.byType(Column)).first), column), isTrue);

    // More text streams in: earlier blocks are reused as they were.
    await tester.pumpWidget(app('${first}New words'));
    final grown = tester.widget<Column>(find.descendant(of: find.byType(ChatMarkdown), matching: find.byType(Column)).first);
    expect(grown.children.length, firstBlocks.length + 1);
    for (var i = 0; i < firstBlocks.length; i++) {
      expect(identical(grown.children[i], firstBlocks[i]), isTrue, reason: 'block $i was rebuilt');
    }
    expect(find.textContaining('New words', findRichText: true), findsOneWidget);
  });

  group('themes', () {
    test('the same appearance gives back the same theme', () {
      const a = Appearance();
      expect(identical(AppTheme.light(a), AppTheme.light(a)), isTrue);
      expect(identical(AppTheme.dark(a), AppTheme.dark(const Appearance())), isTrue);
      // Light or dark mode doesn't change either theme.
      expect(identical(AppTheme.light(a), AppTheme.light(a.copyWith(mode: ThemeMode.dark))), isTrue);
      expect(identical(AppTheme.light(a), AppTheme.light(a.copyWith(schemeId: 'blue'))), isFalse);
    });

    test('wallpaper themes with the same values are equal', () {
      final scheme = ColorScheme.fromSeed(seedColor: Colors.purple);
      const spec = WallpaperSpec();
      expect(WallpaperTheme.of(spec, scheme), WallpaperTheme.of(spec, scheme));
      expect(WallpaperTheme.of(spec, scheme).hashCode, WallpaperTheme.of(spec, scheme).hashCode);
      expect(WallpaperTheme.of(spec, scheme) == WallpaperTheme.of(spec.copyWith(intensity: 0.9), scheme), isFalse);
    });
  });

  test('thumbnails decode at the size they cover, never larger than the picture', () {
    // A 4000 x 3000 photo in a 336 x 252 box: scaled to exactly cover it.
    var t = coverTargetSize(4000, 3000, 336, 252);
    expect((t.width, t.height), (336, 252));
    // A tall screenshot covers the box's width.
    t = coverTargetSize(1170, 2532, 336, 252);
    expect(t.width, 336);
    expect(t.height! >= 252, isTrue);
    // A small picture stays as it is.
    t = coverTargetSize(100, 80, 336, 252);
    expect((t.width, t.height), (100, 80));
  });

  testWidgets('a settled entrance adds no layer', (tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Entrance(child: Text('row')),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.layers.whereType<OpacityLayer>(), isNotEmpty, reason: 'fading in');
    await tester.pumpAndSettle();
    expect(tester.layers.whereType<OpacityLayer>(), isEmpty, reason: 'settled');
    expect(find.text('row'), findsOneWidget);
  });

  testWidgets('a streamed word rebuilds only the reply it lands in', (tester) async {
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final backend = FakeBackend()
      ..storedMessages = [
        ChatMessageView(id: 'q1', role: 'user', text: 'First question', createdAt: DateTime(2026, 1, 1, 10)),
        ChatMessageView(id: 'a1', role: 'assistant', text: 'First answer', createdAt: DateTime(2026, 1, 1, 10, 1)),
      ];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [backendProvider.overrideWithValue(backend), localCacheProvider.overrideWithValue(const NoCache())],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const ChatScreen(botId: botId, conversationId: convId),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('messageInput')), 'Go on');
    await tester.pump();
    await tester.tap(find.byKey(const Key('sendButton')));
    await tester.pump();
    backend.runEventsController.add(ev(1, 'message.delta', {'message_id': 'live', 'text': 'Here '}));
    await tester.pump();
    final question = tester.widget<UserBubble>(find.widgetWithText(UserBubble, 'First question'));
    final answer = tester.widget<AssistantMessage>(find.byWidgetPredicate((w) => w is AssistantMessage && w.entry.id == 'a1'));
    final live = tester.widget<AssistantMessage>(find.byWidgetPredicate((w) => w is AssistantMessage && w.entry.id == 'live'));
    final composer = tester.widget<ChatComposer>(find.byType(ChatComposer));
    final header = tester.widget<ShellHeader>(find.byType(ShellHeader));

    backend.runEventsController.add(ev(2, 'message.delta', {'message_id': 'live', 'text': 'it comes.'}));
    await tester.pump();
    expect(identical(tester.widget<UserBubble>(find.widgetWithText(UserBubble, 'First question')), question), isTrue);
    expect(identical(tester.widget<AssistantMessage>(find.byWidgetPredicate((w) => w is AssistantMessage && w.entry.id == 'a1')), answer), isTrue);
    final grown = tester.widget<AssistantMessage>(find.byWidgetPredicate((w) => w is AssistantMessage && w.entry.id == 'live'));
    expect(identical(grown, live), isFalse);
    expect(grown.entry.text, 'Here it comes.');
    // The header and the composer around the thread aren't rebuilt for a word.
    expect(identical(tester.widget<ChatComposer>(find.byType(ChatComposer)), composer), isTrue);
    expect(identical(tester.widget<ShellHeader>(find.byType(ShellHeader)), header), isTrue);

    // Inside the reply, the paragraphs already finished are kept as they were. (In the chat,
    // Theme.of hands back a new but equal theme each frame; the cache must survive that.)
    List<Widget> blocks() => tester.widget<Column>(find.descendant(of: find.byType(ChatMarkdown).last, matching: find.byType(Column)).first).children;
    backend.runEventsController.add(ev(3, 'message.delta', {'message_id': 'live', 'text': '\n\n$_lead${'A finished paragraph.\n\n' * 3}Still'}));
    await tester.pump();
    final before = blocks();
    backend.runEventsController.add(ev(4, 'message.delta', {'message_id': 'live', 'text': ' typing'}));
    await tester.pump();
    final after = blocks();
    expect(after.length, before.length);
    for (var i = 0; i < before.length - 1; i++) {
      expect(identical(after[i], before[i]), isTrue, reason: 'block $i was parsed again');
    }
  });

  testWidgets('opening a chat with history never flashes empty suggestions or top of thread', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final backend = FakeBackend()
      ..storedMessages = [
        for (var i = 1; i <= 20; i++)
          ChatMessageView(
            id: 'm$i',
            role: i.isOdd ? 'user' : 'assistant',
            text: 'History line $i with enough words to fill the thread vertically.',
            createdAt: DateTime(2026, 1, 1, 10, i),
          ),
      ];
    final container = ProviderContainer(
      overrides: [
        backendProvider.overrideWithValue(backend),
        localCacheProvider.overrideWithValue(const NoCache()),
      ],
    );
    addTearDown(container.dispose);

    Widget buildChat() => UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const ChatScreen(botId: botId, conversationId: convId),
      ),
    );

    await tester.pumpWidget(buildChat());
    // Frame 1: before open() microtask completes, empty-state starter cards must not flash.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.textContaining('Research'), findsNothing);

    // Next frame: messages arrive and the bottom of the history is immediately visible on Frame 1
    // without needing post-frame scroll jumps from the top of the thread.
    await tester.pump();
    expect(find.textContaining('History line 20'), findsOneWidget);
    expect(find.textContaining('History line 1 '), findsNothing);

    // Re-opening the chat keeps existing messages on screen without flashing a spinner.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(buildChat());
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.textContaining('History line 20'), findsOneWidget);
  });
}
