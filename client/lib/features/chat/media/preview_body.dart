import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:re_highlight/languages/bash.dart';
import 'package:re_highlight/languages/cpp.dart';
import 'package:re_highlight/languages/css.dart';
import 'package:re_highlight/languages/dart.dart';
import 'package:re_highlight/languages/go.dart';
import 'package:re_highlight/languages/ini.dart';
import 'package:re_highlight/languages/java.dart';
import 'package:re_highlight/languages/javascript.dart';
import 'package:re_highlight/languages/json.dart';
import 'package:re_highlight/languages/kotlin.dart';
import 'package:re_highlight/languages/python.dart';
import 'package:re_highlight/languages/ruby.dart';
import 'package:re_highlight/languages/rust.dart';
import 'package:re_highlight/languages/sql.dart';
import 'package:re_highlight/languages/swift.dart';
import 'package:re_highlight/languages/typescript.dart';
import 'package:re_highlight/languages/xml.dart';
import 'package:re_highlight/languages/yaml.dart';
import 'package:re_highlight/re_highlight.dart';
import 'package:re_highlight/styles/github-dark.dart';
import 'package:re_highlight/styles/github.dart';

import '../../../core/backend.dart';
import '../../../core/providers.dart';
import '../../../core/widgets.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_tokens.dart';
import '../../../ui/bottom_padding.dart';
import '../../files/file_preview.dart';
import '../widgets/chat_markdown.dart';
import 'chat_audio.dart';
import 'chat_pdf.dart';
import 'chat_video.dart';
import 'media_kind.dart';

/// What a file preview shows for each kind of file: pictures zoom, videos and sounds play, PDFs
/// page, Office files show as a PDF the computer makes, tables lay out as tables, code is
/// colored. Anything else gets [unsupported], with Open and Save above it.
class PreviewBody extends StatelessWidget {
  const PreviewBody({
    super.key,
    required this.name,
    required this.bytes,
    required this.computerId,
    required this.path,
    required this.onOpen,
    required this.unsupported,
  });

  final String name;
  final Uint8List bytes;
  final String computerId;
  final String path;
  final VoidCallback onOpen;
  final Widget Function([String? hint]) unsupported;

  AttachmentRef get _ref => AttachmentRef(
    path: path,
    name: name,
    mimeType: mimeFor(name),
    size: bytes.length,
  );

  @override
  Widget build(BuildContext context) {
    final mime = mimeFor(name);
    final ext = name.contains('.') ? name.split('.').last.toLowerCase() : '';
    switch (mediaKindOf(name, mime)) {
      case MediaKind.svg:
        return InteractiveViewer(
          maxScale: 8,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpace.lg),
              child: SvgPicture.memory(
                bytes,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => unsupported(),
              ),
            ),
          ),
        );
      case MediaKind.image || MediaKind.gif:
        // HEIC decodes on Apple platforms; elsewhere it falls through to Open.
        return InteractiveViewer(
          maxScale: 6,
          child: Center(
            child: Image.memory(
              bytes,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => unsupported(),
            ),
          ),
        );
      case MediaKind.video:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpace.md),
            child: ChatVideo(
              attachment: _ref,
              computerId: computerId.isEmpty ? null : computerId,
              maxWidth: 720,
            ),
          ),
        );
      case MediaKind.audio:
        return Center(
          child: ChatAudio(
            attachment: _ref,
            computerId: computerId.isEmpty ? null : computerId,
          ),
        );
      case MediaKind.pdf:
        if (!mediaPluginsAvailable) return unsupported();
        return PdfPages(bytes: bytes, name: name);
      case MediaKind.office:
        if (computerId.isEmpty) return unsupported();
        return _OfficePreview(
          computerId: computerId,
          path: path,
          name: name,
          unsupported: unsupported,
        );
      case MediaKind.other:
        break;
    }
    final isText =
        mime.startsWith('text/') ||
        mime == 'application/json' ||
        mime == 'text/tab-separated-values';
    if (!isText) return unsupported(context.l10n.previewUnavailable);
    final text = utf8.decode(
      bytes.length > 400 * 1024 ? bytes.sublist(0, 400 * 1024) : bytes,
      allowMalformed: true,
    );
    if (mime == 'text/markdown') {
      return SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          AppSpace.lg,
          AppSpace.lg,
          AppSpace.lg,
          BottomPadding.of(context, minimum: AppSpace.lg),
        ),
        child: ChatMarkdown(data: text),
      );
    }
    if (ext == 'csv' || ext == 'tsv') {
      return CsvTable(text: text, separator: ext == 'tsv' ? '\t' : ',');
    }
    return _CodeView(
      text: text,
      language: _languageFor(ext),
      footer: ext == 'html' || ext == 'htm'
          ? Padding(
              padding: const EdgeInsets.only(top: AppSpace.sm),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: OutlinedButton.icon(
                  key: const Key('openInBrowser'),
                  onPressed: onOpen,
                  icon: const Icon(LucideIcons.globe, size: 18),
                  label: Text(
                    opensInDefaultApp
                        ? context.l10n.openInBrowser
                        : context.l10n.shareFile,
                  ),
                ),
              ),
            )
          : null,
    );
  }
}

class _OfficePreview extends ConsumerStatefulWidget {
  const _OfficePreview({
    required this.computerId,
    required this.path,
    required this.name,
    required this.unsupported,
  });
  final String computerId;
  final String path;
  final String name;
  final Widget Function([String? hint]) unsupported;

  @override
  ConsumerState<_OfficePreview> createState() => _OfficePreviewState();
}

class _OfficePreviewState extends ConsumerState<_OfficePreview> {
  late final Future<Uint8List?> _pdf = ref
      .read(backendProvider)
      .computerFilePdf(widget.computerId, widget.path)
      .catchError((Object _) => null);

  @override
  Widget build(BuildContext context) => FutureBuilder<Uint8List?>(
    future: _pdf,
    builder: (context, snap) {
      if (snap.connectionState != ConnectionState.done) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: AppSpace.md),
              Text(
                context.l10n.convertingToPdf,
                style: context.textTheme.bodyMedium?.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        );
      }
      final pdf = snap.data;
      if (pdf == null || !mediaPluginsAvailable) {
        return widget.unsupported();
      }
      return PdfPages(bytes: pdf, name: '${widget.name}.pdf');
    },
  );
}

/// A CSV or TSV file as a table: the header row stays put while the rows scroll under it, and
/// wide tables scroll sideways. Shows the first [maxRows] rows.
class CsvTable extends StatelessWidget {
  const CsvTable({
    super.key,
    required this.text,
    this.separator = ',',
    this.maxRows = 500,
  });
  final String text;
  final String separator;
  final int maxRows;

  @override
  Widget build(BuildContext context) {
    final all = parseCsv(text, separator: separator, maxRows: maxRows + 1);
    if (all.isEmpty) return const SizedBox.shrink();
    final header = all.first;
    final rows = all.skip(1).take(maxRows).toList();
    final columns = all.fold<int>(0, (n, r) => math.max(n, r.length));
    // Each column as wide as its longest cell (within reason).
    final widths = [
      for (var c = 0; c < columns; c++)
        (all
                        .take(60)
                        .map((r) => c < r.length ? r[c].length : 0)
                        .fold<int>(0, math.max) *
                    7.5 +
                24)
            .clamp(64.0, 280.0),
    ];
    final total = widths.fold<double>(0, (a, b) => a + b);
    final scheme = context.colorScheme;
    final hairline = context.appColors.hairline;
    Widget row(List<String> cells, {bool head = false, int index = 0}) =>
        Container(
          decoration: BoxDecoration(
            color: head
                ? scheme.surfaceContainerHigh
                : (index.isOdd ? scheme.surfaceContainerLowest : null),
            border: Border(bottom: BorderSide(color: hairline)),
          ),
          child: Row(
            children: [
              for (var c = 0; c < columns; c++)
                SizedBox(
                  width: widths[c],
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Text(
                      c < cells.length ? cells[c] : '',
                      maxLines: head ? 2 : 3,
                      overflow: TextOverflow.ellipsis,
                      style: head
                          ? context.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            )
                          : context.textTheme.bodySmall,
                    ),
                  ),
                ),
            ],
          ),
        );
    return Column(
      key: const Key('csvTable'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Scrollbar(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: total,
                child: Column(
                  children: [
                    row(header, head: true),
                    Expanded(
                      child: ListView.builder(
                        padding: EdgeInsets.only(
                          bottom: BottomPadding.of(
                            context,
                            minimum: AppSpace.md,
                          ),
                        ),
                        itemCount: rows.length,
                        itemBuilder: (_, i) => row(rows[i], index: i),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (all.length > maxRows + 1)
          Padding(
            padding: const EdgeInsets.all(AppSpace.sm),
            child: Text(
              context.l10n.tableFirstRows(maxRows),
              textAlign: TextAlign.center,
              style: context.textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }
}

/// Splits CSV text into rows of cells: quoted cells may hold separators, newlines and doubled
/// quotes.
List<List<String>> parseCsv(
  String text, {
  String separator = ',',
  int maxRows = 1 << 30,
}) {
  final rows = <List<String>>[];
  var row = <String>[];
  final cell = StringBuffer();
  var quoted = false;
  for (var i = 0; i < text.length && rows.length < maxRows; i++) {
    final ch = text[i];
    if (quoted) {
      if (ch == '"') {
        if (i + 1 < text.length && text[i + 1] == '"') {
          cell.write('"');
          i++;
        } else {
          quoted = false;
        }
      } else {
        cell.write(ch);
      }
    } else if (ch == '"' && cell.isEmpty) {
      quoted = true;
    } else if (ch == separator) {
      row.add(cell.toString());
      cell.clear();
    } else if (ch == '\n' || ch == '\r') {
      if (ch == '\r' && i + 1 < text.length && text[i + 1] == '\n') i++;
      row.add(cell.toString());
      cell.clear();
      if (!(row.length == 1 && row.first.isEmpty)) rows.add(row);
      row = <String>[];
    } else {
      cell.write(ch);
    }
  }
  if ((cell.isNotEmpty || row.isNotEmpty) && rows.length < maxRows) {
    row.add(cell.toString());
    rows.add(row);
  }
  return rows;
}

String? _languageFor(String ext) => switch (ext) {
  'json' => 'json',
  'yaml' || 'yml' => 'yaml',
  'xml' || 'html' || 'htm' || 'svg' => 'xml',
  'css' => 'css',
  'js' || 'jsx' || 'mjs' => 'javascript',
  'ts' || 'tsx' => 'typescript',
  'dart' => 'dart',
  'py' => 'python',
  'rb' => 'ruby',
  'go' => 'go',
  'rs' => 'rust',
  'java' => 'java',
  'kt' => 'kotlin',
  'swift' => 'swift',
  'c' || 'h' || 'cpp' => 'cpp',
  'sh' || 'bash' || 'zsh' => 'bash',
  'sql' => 'sql',
  'ini' || 'toml' || 'conf' || 'env' => 'ini',
  _ => null,
};

final Highlight _highlight = Highlight()
  ..registerLanguages({
    'json': langJson,
    'yaml': langYaml,
    'xml': langXml,
    'css': langCss,
    'javascript': langJavascript,
    'typescript': langTypescript,
    'dart': langDart,
    'python': langPython,
    'ruby': langRuby,
    'go': langGo,
    'rust': langRust,
    'java': langJava,
    'kotlin': langKotlin,
    'swift': langSwift,
    'cpp': langCpp,
    'bash': langBash,
    'sql': langSql,
    'ini': langIni,
  });

/// Text in a code panel, colored by [language] when it's one we know (and not huge).
class _CodeView extends StatelessWidget {
  const _CodeView({required this.text, this.language, this.footer});
  final String text;
  final String? language;
  final Widget? footer;

  TextSpan? _span(BuildContext context) {
    final lang = language;
    if (lang == null || text.length > 200 * 1024) return null;
    try {
      final theme = Map<String, TextStyle>.of(
        context.isDark ? githubDarkTheme : githubTheme,
      )..remove('root');
      final renderer = TextSpanRenderer(
        AppText.mono.copyWith(color: context.colorScheme.onSurface),
        theme,
      );
      _highlight.highlight(code: text, language: lang).render(renderer);
      return renderer.span;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final span = _span(context);
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        AppSpace.md,
        AppSpace.md,
        AppSpace.md,
        BottomPadding.of(context, minimum: AppSpace.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpace.md),
            decoration: BoxDecoration(
              color: context.appColors.codeBackground,
              borderRadius: BorderRadius.circular(AppRadius.row),
              border: Border.all(color: context.appColors.hairline),
            ),
            child: span == null
                ? SelectableText(text, style: AppText.mono)
                : SelectableText.rich(span, key: const Key('codeHighlighted')),
          ),
          ?footer,
        ],
      ),
    );
  }
}
