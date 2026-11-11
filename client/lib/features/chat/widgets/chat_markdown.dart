import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:markdown_widget/markdown_widget.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_tokens.dart';
import '../../files/file_preview.dart';

/// Bot replies as Markdown in the app's type and surfaces: comfortable paragraphs, Fraunces headings,
/// and code in rounded panels with the language and a copy button.
///
/// Parsing is the expensive part, so the blocks are built once per run of text and theme and kept:
/// a chat rebuilding on every streamed word reuses every message as it was, and the message still
/// streaming parses only its last run (see [markdownChunks]).
class ChatMarkdown extends StatefulWidget {
  const ChatMarkdown({super.key, required this.data, this.selectable = true});
  final String data;
  final bool selectable;

  @override
  State<ChatMarkdown> createState() => _ChatMarkdownState();
}

class _ChatMarkdownState extends State<ChatMarkdown> {
  final _generator = MarkdownGenerator();
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
        H1Config(style: heading(22)),
        H2Config(style: heading(19)),
        H3Config(style: heading(17)),
        H4Config(style: heading(15, serif: false)),
        LinkConfig(
          style: TextStyle(color: scheme.primary, decoration: TextDecoration.underline, decorationColor: scheme.primary.withValues(alpha: 0.4)),
          onTap: (url) {
            final uri = Uri.tryParse(url);
            if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
              launchUrl(uri, mode: LaunchMode.externalApplication);
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
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
          margin: const EdgeInsets.symmetric(vertical: 8),
          textStyle: AppText.mono,
          wrapper: (child, code, language) => _CodeBlock(code: code, language: language, child: child),
        ),
        BlockquoteConfig(sideColor: scheme.primary.withValues(alpha: 0.5), textColor: scheme.onSurfaceVariant, sideWith: 3),
        HrConfig(color: colors.hairline, height: 1),
        ListConfig(
          marker: (isOrdered, depth, index) => _ListMarker(isOrdered: isOrdered, index: index),
        ),
        TableConfig(
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
          top: 12,
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
