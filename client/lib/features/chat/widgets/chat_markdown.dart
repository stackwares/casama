import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:markdown_widget/markdown_widget.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_tokens.dart';
import '../../files/file_preview.dart';
import '../media/markdown_image.dart';
import 'mentions.dart';
import '../../../core/link_browser.dart';
import '../../../core/nav.dart';
import '../../../core/open_links.dart';

/// Bot replies as Markdown in the app's type and surfaces: comfortable paragraphs, Fraunces headings,
/// and code in rounded panels with the language and a copy button.
///
/// Parsing is the expensive part, so the blocks are built once per run of text and theme and kept:
/// a chat rebuilding on every streamed word reuses every message as it was, and the message still
/// streaming parses only its last run (see [markdownChunks]).
class ChatMarkdown extends StatefulWidget {
  const ChatMarkdown({
    super.key,
    required this.data,
    this.selectable = true,
    this.appLinks = false,
    this.onLinkTap,
  });
  final String data;
  final bool selectable;

  /// Opens `casama://app/<route>` and `casama.ai/open/<route>` links inside the app. Only for
  /// text whose links the server already checked against the place list (Casama Help, D-431):
  /// in bot replies these stay off, since routes like `/runs/<id>/stop` act when opened.
  final bool appLinks;
  final void Function(String url)? onLinkTap;

  @override
  State<ChatMarkdown> createState() => _ChatMarkdownState();
}

class _ChatMarkdownState extends State<ChatMarkdown> {
  var _generator = MarkdownGenerator();

  /// The group's members when the reply is in a group chat: their @mentions show as pills.
  String? _mentions;
  var _blocks = <String, List<Widget>>{};
  (ColorScheme, TextTheme, AppColors?)? _style;
  MarkdownConfig? _config;
  String? _data;
  Widget? _built;

  @override
  Widget build(BuildContext context) {
    // What the blocks are styled from, compared by value: Theme.of can return an equal theme as a
    // new object on every frame, which would throw the cache away each time.
    final theme = Theme.of(context);
    final style = (theme.colorScheme, theme.textTheme, theme.extension<AppColors>());
    final scope = MentionScope.maybeOf(context);
    if (scope?.signature != _mentions) {
      _mentions = scope?.signature;
      _generator = scope == null ? MarkdownGenerator() : mentionMarkdownGenerator(scope);
      _blocks = {};
      _built = null;
    }
    if (style != _style) {
      _style = style;
      _config = _configFor(context);
      _blocks = {};
      _built = null;
    }
    final data = widget.data;
    if (_built == null || data != _data) {
      final kept = <String, List<Widget>>{};
      final children = <Widget>[];
      for (final chunk in markdownChunks(data)) {
        final blocks = kept[chunk] ?? _blocks[chunk] ?? _generator.buildWidgets(chunk, config: _config);
        kept[chunk] = blocks;
        children.addAll(blocks);
      }
      _blocks = kept;
      _data = data;
      // The same instance every build: Flutter skips the whole subtree when nothing changed.
      _built = Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: children);
    }
    return widget.selectable ? SelectionArea(child: _built!) : _built!;
  }

  MarkdownConfig _configFor(BuildContext context) {
    final scheme = context.colorScheme;
    final tt = context.textTheme;
    final colors = context.appColors;
    final dark = context.isDark;
    final body = tt.bodyLarge!.copyWith(height: 1.55, color: scheme.onSurface);
    TextStyle heading(double size, {bool serif = true}) => (serif ? tt.headlineSmall! : tt.titleMedium!).copyWith(
      fontSize: size,
      fontWeight: FontWeight.w700,
      height: 1.3,
      letterSpacing: serif ? -0.2 : -0.1,
      color: scheme.onSurface,
    );
    final codePanel = BoxDecoration(
      color: colors.codeBackground,
      borderRadius: BorderRadius.circular(AppRadius.row),
      border: Border.all(color: colors.hairline),
    );
    final base = dark ? MarkdownConfig.darkConfig : MarkdownConfig.defaultConfig;
    return base.copy(
      configs: [
        PConfig(textStyle: body),
        // Images in the reply show bounded and tappable, from the web or the bot's computer.
        ImgConfig(builder: (url, attributes) => ChatMarkdownImage(src: url, alt: attributes['alt'] ?? '')),
        H1Config(style: heading(22)),
        H2Config(style: heading(19)),
        H3Config(style: heading(17)),
        H4Config(style: heading(15, serif: false)),
        LinkConfig(
          style: TextStyle(color: scheme.primary, decoration: TextDecoration.underline, decorationColor: scheme.primary.withValues(alpha: 0.4)),
          onTap: (url) {
            final uri = Uri.tryParse(url);
            if (widget.appLinks && uri != null && uri.scheme == 'casama' && uri.host == 'app') {
              final target = macLinkLocation(uri);
              if (target != null) {
                widget.onLinkTap?.call(url);
                context.pushOnce(target);
                return;
              }
            }
            if (widget.appLinks && uri != null && (uri.scheme == 'https' || uri.scheme == 'http') && (uri.host == 'casama.ai' || uri.host == 'www.casama.ai')) {
              final target = openLinkTarget(uri);
              if (target != null) {
                widget.onLinkTap?.call(url);
                context.pushOnce(target);
                return;
              }
            }
            if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
              widget.onLinkTap?.call(url);
              openWebLink(uri);
              return;
            }
            // Files the bot made ("sandbox:/home/casama/workspace/x.md", "workspace/x.md") open in the app.
            final path = computerPathFromLink(url);
            final files = FileLinkScope.maybeOf(context);
            if (path != null && files != null) files.open(path);
          },
        ),
        CodeConfig(
          style: AppText.mono.copyWith(
            fontSize: 13.5,
            backgroundColor: scheme.primary.withValues(alpha: dark ? 0.16 : 0.08),
            color: scheme.onSurface,
          ),
        ),
        (dark ? PreConfig.darkConfig : const PreConfig()).copy(
          decoration: codePanel,
          // The top padding leaves room for the language and copy button row ([_CodeBlock]), which
          // otherwise sat on top of the first line of code.
          padding: const EdgeInsets.fromLTRB(14, 40, 14, 14),
          margin: const EdgeInsets.symmetric(vertical: 8),
          textStyle: AppText.mono,
          // Code the highlighter leaves unstyled (names, punctuation) is mono too; without this it
          // took the paragraph's font while keywords were mono.
          styleNotMatched: AppText.mono,
          wrapper: (child, code, language) => _CodeBlock(code: code, language: language, child: child),
        ),
        BlockquoteConfig(sideColor: scheme.primary.withValues(alpha: 0.5), textColor: scheme.onSurfaceVariant, sideWith: 3),
        HrConfig(color: colors.hairline, height: 1),
        ListConfig(
          marker: (isOrdered, depth, index) => _ListMarker(isOrdered: isOrdered, index: index),
        ),
        TableConfig(
          // Columns fit their text up to a cap, past which the text wraps; a table wider than the
          // bubble then scrolls sideways instead of being cut off (see [ChatTable]).
          defaultColumnWidth: const MinColumnWidth(IntrinsicColumnWidth(), FixedColumnWidth(ChatTable.maxColumnWidth)),
          wrapper: (table) => ChatTable(table: table),
          border: TableBorder.all(color: colors.hairline, borderRadius: BorderRadius.circular(AppRadius.row)),
          headerRowDecoration: BoxDecoration(color: scheme.surfaceContainer),
          headerStyle: body.copyWith(fontWeight: FontWeight.w700, fontSize: 14),
          bodyStyle: body.copyWith(fontSize: 14),
        ),
      ],
    );
  }
}

final _fenceOpen = RegExp(r'^ {0,3}(`{3,}|~{3,})');
final _listItem = RegExp(r'^([-+*]|\d{1,9}[.)])(\s|$)');
// Link reference and footnote definitions, and HTML blocks, can reach across blank lines.
final _unsplittable = RegExp(r'^ {0,3}(\[[^\]]+\]:|<)', multiLine: true);

/// Splits Markdown into runs of whole top-level blocks that parse the same on their own as within
/// the whole text. A run ends only at a blank line outside fenced code whose next line starts a new
/// block: not indented (a list item's continuation or indented code), not a list item, and not a
/// quote. Text with link definitions or HTML blocks stays in one run.
List<String> markdownChunks(String text) {
  if (text.length < 400 || _unsplittable.hasMatch(text)) return [text];
  final out = <String>[];
  var start = 0;
  var pos = 0;
  var blankBefore = false;
  String? fence;
  while (pos < text.length) {
    var end = text.indexOf('\n', pos);
    if (end < 0) end = text.length;
    final line = text.substring(pos, end);
    if (fence != null) {
      final t = line.trimLeft();
      if (line.length - t.length <= 3 && t.startsWith(fence) && t.replaceAll(fence[0], '').trim().isEmpty) fence = null;
    } else if (line.trim().isEmpty) {
      blankBefore = true;
    } else {
      final first = line.codeUnitAt(0);
      if (blankBefore && pos > start && first != 0x20 && first != 0x09 && first != 0x3E && !_listItem.hasMatch(line)) {
        out.add(text.substring(start, pos));
        start = pos;
      }
      blankBefore = false;
      final open = _fenceOpen.firstMatch(line);
      if (open != null) fence = open.group(1);
    }
    pos = end + 1;
  }
  if (start < text.length) out.add(text.substring(start));
  return out;
}

class _ListMarker extends StatelessWidget {
  const _ListMarker({required this.isOrdered, required this.index});
  final bool isOrdered;
  final int index;

  @override
  Widget build(BuildContext context) {
    final color = context.colorScheme.onSurfaceVariant;
    if (isOrdered) {
      return Padding(
        padding: const EdgeInsets.only(right: 6, top: 2),
        child: Text(
          '${index + 1}.',
          style: context.textTheme.bodyLarge?.copyWith(color: color, fontWeight: FontWeight.w600, fontFeatures: AppText.tabular),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(right: 8, top: 10),
      child: Container(
        width: 5,
        height: 5,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}

class _CodeBlock extends StatefulWidget {
  const _CodeBlock({required this.child, required this.code, required this.language});
  final Widget child;
  final String code;
  final String language;

  @override
  State<_CodeBlock> createState() => _CodeBlockState();
}

class _CodeBlockState extends State<_CodeBlock> {
  var _copied = false;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.code));
    HapticFeedback.lightImpact();
    if (!mounted) return;
    setState(() => _copied = true);
    await Future<void>.delayed(const Duration(milliseconds: 1600));
    if (mounted) setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    return Stack(
      children: [
        widget.child,
        Positioned(
          top: 8,
          right: 6,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.language.isNotEmpty)
                Text(
                  widget.language,
                  style: context.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant, fontWeight: FontWeight.w600),
                ),
              IconButton(
                tooltip: MaterialLocalizations.of(context).copyButtonLabel,
                visualDensity: VisualDensity.compact,
                iconSize: 16,
                onPressed: _copy,
                icon: AnimatedSwitcher(
                  duration: AppMotion.of(context, AppMotion.fast),
                  child: Icon(
                    _copied ? LucideIcons.check : LucideIcons.copy,
                    key: ValueKey(_copied),
                    color: _copied ? context.appColors.positive : scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A Markdown table in a reply. One that fits shows as it is. A wider one scrolls sideways under a
/// scrollbar, its right edge fades while there is more to see, and "View full table" opens it on its
/// own screen, where turning the phone sideways shows more columns.
class ChatTable extends StatefulWidget {
  const ChatTable({super.key, required this.table});
  final Widget table;

  /// The widest a column grows before its text wraps.
  static const maxColumnWidth = 240.0;

  @override
  State<ChatTable> createState() => _ChatTableState();
}

class _ChatTableState extends State<ChatTable> {
  final _scroll = ScrollController();
  var _overflows = false;
  var _moreRight = false;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  bool _onMetrics(ScrollMetrics m) {
    final overflows = m.maxScrollExtent > 0.5;
    final moreRight = m.pixels < m.maxScrollExtent - 0.5;
    if (overflows != _overflows || moreRight != _moreRight) {
      setState(() {
        _overflows = overflows;
        _moreRight = moreRight;
      });
    }
    return false;
  }

  void _openFull() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        settings: const RouteSettings(name: '/chat/table'),
        builder: (_) => _FullTablePage(table: widget.table),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    Widget scroller = NotificationListener<ScrollMetricsNotification>(
      onNotification: (n) => _onMetrics(n.metrics),
      child: NotificationListener<ScrollNotification>(
        onNotification: (n) => n.depth == 0 && _onMetrics(n.metrics),
        child: Scrollbar(
          controller: _scroll,
          thumbVisibility: _overflows,
          child: SingleChildScrollView(
            controller: _scroll,
            scrollDirection: Axis.horizontal,
            // Room under the table so the scrollbar doesn't sit on the last row.
            padding: EdgeInsets.only(bottom: _overflows ? 10 : 0),
            child: widget.table,
          ),
        ),
      ),
    );
    // Always in the tree (only the gradient changes) so the scroll position survives the fade
    // coming and going.
    final fade = _moreRight ? Colors.transparent : Colors.black;
    scroller = ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (rect) => LinearGradient(
        colors: [Colors.black, Colors.black, fade],
        stops: [0, ((rect.width - 40) / rect.width).clamp(0.0, 1.0), 1],
      ).createShader(rect),
      child: scroller,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          scroller,
          if (_overflows)
            TextButton.icon(
              onPressed: _openFull,
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                foregroundColor: scheme.onSurfaceVariant,
                textStyle: context.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              icon: const Icon(LucideIcons.maximize2, size: 15),
              label: const Text('View full table'),
            ),
        ],
      ),
    );
  }
}

class _FullTablePage extends StatelessWidget {
  const _FullTablePage({required this.table});
  final Widget table;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Table')),
      body: SafeArea(
        child: SelectionArea(
          child: Scrollbar(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: table,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

final _tableSeparator = RegExp(r'^\s*\|?\s*:?-+:?\s*(\|\s*:?-+:?\s*)*\|?\s*$');
final _openLink = RegExp(r'^!?\[[^\]\n]*$|^!?\[[^\]\n]*\]\([^)\s]*$');

/// Closes what a reply still streaming has opened but not finished, so half-written Markdown
/// doesn't flash raw and then snap: an open code fence is closed, as are `code`, **bold** and
/// ~~strike~~ left open on the last line; a marker with nothing after it yet, a link still being
/// typed, a table row still coming and a table whose separator row hasn't arrived are held back.
/// Only for text that is still growing; a finished reply shows as written.
String healStreamingMarkdown(String text) {
  // Fenced code: an open fence runs to the end, so close it.
  String? fence;
  var lineStart = 0;
  for (var pos = 0; pos <= text.length;) {
    var end = text.indexOf('\n', pos);
    if (end < 0) end = text.length;
    final line = text.substring(pos, end);
    final t = line.trimLeft();
    if (fence == null) {
      final open = _fenceOpen.firstMatch(line);
      if (open != null) fence = open.group(1);
    } else if (line.length - t.length <= 3 && t.startsWith(fence) && t.replaceAll(fence[0], '').trim().isEmpty) {
      fence = null;
    }
    lineStart = pos;
    pos = end + 1;
  }
  if (fence != null) {
    // A fence that opened on the last line with only its language so far shows nothing yet.
    return _fenceOpen.hasMatch(text.substring(lineStart)) ? text.substring(0, lineStart).trimRight() : '$text\n$fence';
  }

  var head = text.substring(0, lineStart);
  var line = text.substring(lineStart);

  // Tables: hold back a row still coming, and a table until its separator row arrives.
  if (line.trimLeft().startsWith('|') && (line.trim() == '|' || !line.trimRight().endsWith('|'))) {
    return healStreamingMarkdown(head.isEmpty ? '' : head.substring(0, head.length - 1));
  }
  if (line.trimLeft().startsWith('|')) {
    final rows = text.split('\n').reversed.takeWhile((l) => l.trimLeft().startsWith('|')).toList();
    if (!rows.any(_tableSeparator.hasMatch)) {
      return text.substring(0, text.length - rows.reversed.join('\n').length).trimRight();
    }
    return text;
  }

  // A link or image still being typed shows from its bracket once it's whole.
  final bracket = line.lastIndexOf('[');
  if (bracket >= 0) {
    final from = bracket > 0 && line[bracket - 1] == '!' ? bracket - 1 : bracket;
    if (_openLink.hasMatch(line.substring(from)) && line.length - from < 300) line = line.substring(0, from).trimRight();
  }

  // Inline markers on the last line: code spans first (nothing inside them counts), then ** and ~~.
  final open = <(String, int)>[];
  String? code;
  var codeAt = 0;
  for (var i = 0; i < line.length;) {
    final c = line[i];
    if (c == r'\' && code == null) {
      i += 2;
      continue;
    }
    if (c == '`' || c == '*' || c == '~') {
      var j = i;
      while (j < line.length && line[j] == c) {
        j++;
      }
      final run = line.substring(i, j);
      if (c == '`') {
        if (code == null) {
          code = run;
          codeAt = i;
        } else if (run == code) {
          code = null;
        }
      } else if (code == null && run.length >= 2) {
        final marker = c * 2;
        final k = open.lastIndexWhere((o) => o.$1 == marker);
        if (k >= 0) {
          open.removeRange(k, open.length);
        } else {
          open.add((marker, i));
        }
      }
      i = j;
      continue;
    }
    i++;
  }
  if (code != null) open.add((code, codeAt));
  // Close innermost first; a marker with nothing after it yet is dropped instead.
  for (final (marker, at) in open.reversed) {
    if (line.substring(at + marker.length).trim().isEmpty) {
      line = line.substring(0, at).trimRight();
    } else {
      line = '${line.trimRight()}$marker';
    }
  }
  if (line.isEmpty && head.endsWith('\n')) head = head.substring(0, head.length - 1);
  return '$head$line';
}
