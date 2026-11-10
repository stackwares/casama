import 'dart:convert';
import 'dart:io' show File, Platform;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../ui/adaptive_modal.dart';
import '../chat/widgets/chat_markdown.dart';

/// Turns a file reference a bot wrote into a path for the files API (relative to the computer's
/// workspace, `~/` for the rest of home, or absolute). Returns null for web links and anything
/// that isn't a file. Handles `sandbox:/home/kasama/workspace/x`, `file:///home/kasama/x`,
/// `/home/kasama/workspace/x`, `~/x`, `workspace/x` and plain `x.md`.
String? computerPathFromLink(String link) {
  var s = Uri.decodeFull(link.trim());
  if (s.isEmpty || s.startsWith('#')) return null;
  final lower = s.toLowerCase();
  if (lower.startsWith('http://') || lower.startsWith('https://') || lower.startsWith('mailto:') || lower.startsWith('tel:')) return null;
  for (final prefix in ['sandbox:', 'file://']) {
    if (lower.startsWith(prefix)) s = s.substring(prefix.length);
  }
  if (RegExp(r'^[a-z][a-z0-9+.-]*:', caseSensitive: false).hasMatch(s)) return null;
  const home = '/home/kasama/';
  if (s.startsWith(home)) {
    s = s.substring(home.length);
  } else if (s.startsWith('~/')) {
    s = s.substring(2);
  } else if (s.startsWith('/')) {
    return s;
  } else if (s.startsWith('./')) {
    s = s.substring(2);
  } else if (!s.startsWith('workspace/')) {
    // A bare name ("notes.md") is in the workspace.
    return s.contains('.') || s.contains('/') ? s : null;
  }
  if (s.startsWith('workspace/')) return s.substring('workspace/'.length);
  return '~/$s';
}

String fileNameOf(String path) => path.split('/').where((p) => p.isNotEmpty).lastOrNull ?? path;

const _textTypes = {
  'txt',
  'md',
  'markdown',
  'json',
  'csv',
  'tsv',
  'yaml',
  'yml',
  'toml',
  'xml',
  'html',
  'htm',
  'css',
  'js',
  'ts',
  'tsx',
  'jsx',
  'dart',
  'py',
  'rb',
  'go',
  'rs',
  'java',
  'kt',
  'swift',
  'c',
  'h',
  'cpp',
  'sh',
  'bash',
  'zsh',
  'sql',
  'log',
  'ini',
  'env',
  'conf',
};

String _ext(String name) => name.contains('.') ? name.split('.').last.toLowerCase() : '';

/// A best guess at a file's MIME type from its name.
String mimeFor(String name) => switch (_ext(name)) {
  'png' => 'image/png',
  'jpg' || 'jpeg' => 'image/jpeg',
  'gif' => 'image/gif',
  'webp' => 'image/webp',
  'heic' => 'image/heic',
  'svg' => 'image/svg+xml',
  'pdf' => 'application/pdf',
  'md' || 'markdown' => 'text/markdown',
  'csv' => 'text/csv',
  'json' => 'application/json',
  'html' || 'htm' => 'text/html',
  'zip' => 'application/zip',
  'mp3' => 'audio/mpeg',
  'm4a' => 'audio/mp4',
  'wav' => 'audio/wav',
  'mp4' => 'video/mp4',
  'mov' => 'video/quicktime',
  'doc' => 'application/msword',
  'docx' => 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  'xlsx' => 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  'pptx' => 'application/vnd.openxmlformats-officedocument.presentationml.presentation',
  final e when _textTypes.contains(e) => 'text/plain',
  _ => 'application/octet-stream',
};

IconData fileIconFor(String name) => switch (_ext(name)) {
  'png' || 'jpg' || 'jpeg' || 'gif' || 'webp' || 'heic' || 'svg' => Icons.image_outlined,
  'pdf' => Icons.picture_as_pdf_outlined,
  'md' || 'markdown' || 'txt' => Icons.description_outlined,
  'csv' || 'xlsx' || 'tsv' => Icons.table_chart_outlined,
  'zip' => Icons.folder_zip_outlined,
  'mp3' || 'm4a' || 'wav' => Icons.audiotrack_outlined,
  'mp4' || 'mov' => Icons.movie_outlined,
  final e when _textTypes.contains(e) => Icons.code_rounded,
  _ => Icons.insert_drive_file_outlined,
};

String formatBytes(int n) {
  if (n < 1024) return '$n B';
  if (n < 1024 * 1024) return '${(n / 1024).toStringAsFixed(n < 10 * 1024 ? 1 : 0)} KB';
  return '${(n / 1024 / 1024).toStringAsFixed(1)} MB';
}

/// A file's bytes from a bot's computer, by (computer id, files API path).
final computerFileProvider = FutureProvider.autoDispose.family<Uint8List, (String, String)>(
  (ref, key) => ref.watch(backendProvider).downloadFile(key.$1, key.$2),
);

/// Lets chat content (Markdown links, tool steps, attachments) open files from the bot's computer.
class FileLinkScope extends InheritedWidget {
  const FileLinkScope({super.key, required this.open, required this.computerId, required super.child});
  final void Function(String apiPath) open;

  /// The bot's computer, for thumbnails of attached images.
  final String? computerId;

  static FileLinkScope? maybeOf(BuildContext context) => context.dependOnInheritedWidgetOfExactType<FileLinkScope>();

  @override
  bool updateShouldNotify(FileLinkScope oldWidget) => oldWidget.open != open || oldWidget.computerId != computerId;
}

/// Shows a file from a bot's computer: a preview when the app can render it, plus Open, Save and
/// Share. A sheet on phones, a dialog on larger windows.
Future<void> showComputerFile(BuildContext context, {required String computerId, required String path}) {
  return showAdaptiveSheet<void>(
    context: context,
    heightFactor: 0.85,
    dialogMaxWidth: 760,
    dialogMaxHeight: 820,
    builder: (_) => FilePreview(computerId: computerId, path: path),
  );
}

bool get _desktop => !kIsWeb && (Platform.isMacOS || Platform.isWindows || Platform.isLinux);

class FilePreview extends ConsumerWidget {
  const FilePreview({super.key, required this.computerId, required this.path});
  final String computerId;
  final String path;

  Future<void> _open(BuildContext context, Uint8List bytes) async {
    final name = fileNameOf(path);
    if (_desktop) {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/kasama/$name');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes);
      final ok = await launchUrl(Uri.file(file.path));
      if (!ok && context.mounted) showMessage(context, context.l10n.noAppToOpen(name));
      return;
    }
    await _share(context, bytes);
  }

  Future<void> _save(BuildContext context, Uint8List bytes) async {
    final name = fileNameOf(path);
    // The picker writes the file itself on every platform.
    final saved = await FilePicker.saveFile(fileName: name, bytes: bytes, mimeType: mimeFor(name));
    if (saved != null && context.mounted) showMessage(context, context.l10n.savedFile(name));
  }

  Future<void> _share(BuildContext context, Uint8List bytes) async {
    final name = fileNameOf(path);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile.fromData(bytes, name: name, mimeType: mimeFor(name))],
        fileNameOverrides: [name],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    final name = fileNameOf(path);
    final data = ref.watch(computerFileProvider((computerId, path)));
    final bytes = data.value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpace.lg, 0, AppSpace.md, AppSpace.sm),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.icon),
                ),
                alignment: Alignment.center,
                child: Icon(fileIconFor(name), color: scheme.primary, size: 22),
              ),
              const SizedBox(width: AppSpace.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      [
                        path.startsWith('~/') || path.startsWith('/') ? path : 'workspace/$path',
                        if (bytes != null) formatBytes(bytes.length),
                      ].join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              // Dialogs (larger windows) have no drag handle, so give them a way out.
              if (AppBreakpoints.of(MediaQuery.sizeOf(context).width) != WindowSize.compact)
                IconButton(
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.close_rounded),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpace.md, 0, AppSpace.md, AppSpace.sm),
          child: Wrap(
            spacing: AppSpace.xs,
            runSpacing: AppSpace.xs,
            children: [
              FilledButton.tonalIcon(
                key: const Key('fileOpen'),
                onPressed: bytes == null ? null : () => runGuarded(context, () => _open(context, bytes)),
                icon: const Icon(Icons.open_in_new_rounded, size: 18),
                label: Text(_desktop ? l10n.openFile : l10n.shareFile),
              ),
              OutlinedButton.icon(
                key: const Key('fileSave'),
                onPressed: bytes == null ? null : () => runGuarded(context, () => _save(context, bytes)),
                icon: const Icon(Icons.download_rounded, size: 18),
                label: Text(l10n.saveFile),
              ),
              if (_desktop)
                OutlinedButton.icon(
                  onPressed: bytes == null ? null : () => runGuarded(context, () => _share(context, bytes)),
                  icon: const Icon(Icons.ios_share_rounded, size: 18),
                  label: Text(l10n.shareFile),
                ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: AsyncView(
            value: data,
            onRetry: () => ref.invalidate(computerFileProvider((computerId, path))),
            data: (bytes) => _Body(name: name, bytes: bytes, onOpen: () => _open(context, bytes)),
          ),
        ),
      ],
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.name, required this.bytes, required this.onOpen});
  final String name;
  final Uint8List bytes;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final mime = mimeFor(name);
    if (mime.startsWith('image/') && mime != 'image/svg+xml' && mime != 'image/heic') {
      return InteractiveViewer(
        maxScale: 6,
        child: Center(
          child: Image.memory(
            bytes,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => _Unsupported(name: name, onOpen: onOpen),
          ),
        ),
      );
    }
    final isText = mime.startsWith('text/') || mime == 'application/json';
    if (isText) {
      final text = utf8.decode(bytes.length > 400 * 1024 ? bytes.sublist(0, 400 * 1024) : bytes, allowMalformed: true);
      if (mime == 'text/markdown') {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpace.lg),
          child: ChatMarkdown(data: text),
        );
      }
      return SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpace.md),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpace.md),
          decoration: BoxDecoration(
            color: context.appColors.codeBackground,
            borderRadius: BorderRadius.circular(AppRadius.row),
            border: Border.all(color: context.appColors.hairline),
          ),
          child: SelectableText(text, style: AppText.mono),
        ),
      );
    }
    return _Unsupported(name: name, onOpen: onOpen, hint: l10n.previewUnavailable);
  }
}

class _Unsupported extends StatelessWidget {
  const _Unsupported({required this.name, required this.onOpen, this.hint});
  final String name;
  final VoidCallback onOpen;
  final String? hint;

  @override
  Widget build(BuildContext context) => EmptyState(
    icon: fileIconFor(name),
    title: name,
    message: hint ?? context.l10n.previewUnavailable,
    action: FilledButton.icon(
      onPressed: onOpen,
      icon: const Icon(Icons.open_in_new_rounded, size: 18),
      label: Text(_desktop ? context.l10n.openFile : context.l10n.shareFile),
    ),
  );
}
