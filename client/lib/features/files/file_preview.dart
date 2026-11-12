import 'dart:io' show File, Platform;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/number_format.dart';
import '../../core/providers.dart';
import '../../core/share.dart';
import '../../core/widgets.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_tokens.dart';
import '../../ui/adaptive_modal.dart';
import '../chat/media/preview_body.dart';
import '../../ui/glow_button.dart';

/// Turns a file reference a bot wrote into a path for the files API (relative to the computer's
/// workspace, `~/` for the rest of home, or absolute). Returns null for web links and anything
/// that isn't a file. Handles `sandbox:/home/casama/workspace/x`, `file:///home/casama/x`,
/// `/home/casama/workspace/x`, `~/x`, `workspace/x` and plain `x.md`.
String? computerPathFromLink(String link) {
  var s = Uri.decodeFull(link.trim());
  if (s.isEmpty || s.startsWith('#')) return null;
  final lower = s.toLowerCase();
  if (lower.startsWith('http://') || lower.startsWith('https://') || lower.startsWith('mailto:') || lower.startsWith('tel:')) return null;
  for (final prefix in ['sandbox:', 'file://']) {
    if (lower.startsWith(prefix)) s = s.substring(prefix.length);
  }
  if (RegExp(r'^[a-z][a-z0-9+.-]*:', caseSensitive: false).hasMatch(s)) return null;
  const home = '/home/casama/';
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
  'heic' || 'heif' => 'image/heic',
  'bmp' => 'image/bmp',
  'avif' => 'image/avif',
  'svg' => 'image/svg+xml',
  'pdf' => 'application/pdf',
  'md' || 'markdown' => 'text/markdown',
  'csv' => 'text/csv',
  'tsv' => 'text/tab-separated-values',
  'json' => 'application/json',
  'html' || 'htm' => 'text/html',
  'zip' => 'application/zip',
  'mp3' => 'audio/mpeg',
  'm4a' => 'audio/mp4',
  'aac' => 'audio/aac',
  'wav' => 'audio/wav',
  'ogg' || 'oga' => 'audio/ogg',
  'opus' => 'audio/opus',
  'flac' => 'audio/flac',
  'mp4' || 'm4v' => 'video/mp4',
  'mov' => 'video/quicktime',
  'webm' => 'video/webm',
  'doc' => 'application/msword',
  'rtf' => 'application/rtf',
  'odt' => 'application/vnd.oasis.opendocument.text',
  'ods' => 'application/vnd.oasis.opendocument.spreadsheet',
  'odp' => 'application/vnd.oasis.opendocument.presentation',
  'xls' => 'application/vnd.ms-excel',
  'ppt' => 'application/vnd.ms-powerpoint',
  'docx' => 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  'xlsx' => 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  'pptx' => 'application/vnd.openxmlformats-officedocument.presentationml.presentation',
  final e when _textTypes.contains(e) => 'text/plain',
  _ => 'application/octet-stream',
};

IconData fileIconFor(String name) => switch (_ext(name)) {
  'png' || 'jpg' || 'jpeg' || 'gif' || 'webp' || 'heic' || 'heif' || 'bmp' || 'avif' || 'svg' => LucideIcons.image,
  'pdf' => LucideIcons.fileText,
  'md' || 'markdown' || 'txt' || 'doc' || 'docx' || 'odt' || 'rtf' => LucideIcons.fileText,
  'csv' || 'xlsx' || 'xls' || 'ods' || 'tsv' => LucideIcons.table2,
  'ppt' || 'pptx' || 'odp' => LucideIcons.presentation,
  'zip' => LucideIcons.folderArchive,
  'mp3' || 'm4a' || 'aac' || 'wav' || 'ogg' || 'oga' || 'opus' || 'flac' => LucideIcons.music,
  'mp4' || 'm4v' || 'mov' || 'webm' => LucideIcons.film,
  final e when _textTypes.contains(e) => LucideIcons.codeXml,
  _ => LucideIcons.file,
};

String formatBytes(int n, String locale) {
  if (n < 1024) return '${n.humanizedCount(locale)} B';
  if (n < 1024 * 1024) return '${(n / 1024).humanizedCount(locale, decimalDigits: n < 10 * 1024 ? 1 : 0)} KB';
  return '${(n / 1024 / 1024).humanizedCount(locale, decimalDigits: 1)} MB';
}

/// A file's bytes by (computer id, files API path) from a bot's computer, or a chat media file
/// by its `media:<id>` path (the computer id is ignored then).
final computerFileProvider = FutureProvider.autoDispose.family<Uint8List, (String, String)>(
  (ref, key) => key.$2.startsWith('media:')
      ? ref.watch(backendProvider).chatMedia(key.$2.substring('media:'.length))
      : ref.watch(backendProvider).downloadFile(key.$1, key.$2),
);

/// Opens a file a chat shows: chat media (`media:<id>`) right here, anything else on the bot's
/// computer through [FileLinkScope].
void openChatFile(BuildContext context, String path, {String? name}) {
  if (path.startsWith('media:')) {
    showComputerFile(context, computerId: '', path: path, name: name);
    return;
  }
  FileLinkScope.maybeOf(context)?.open(path);
}

/// Hands [bytes] to the system: opens them in the default app on desktops, shares them on phones.
Future<void> openFileBytes(BuildContext context, String name, Uint8List bytes, {Rect? origin}) async {
  if (_desktop) {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/casama/$name');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes);
    final ok = await launchUrl(Uri.file(file.path));
    if (!ok && context.mounted) showWarning(context, context.l10n.noAppToOpen(name));
    return;
  }
  await shareFiles(
    [XFile.fromData(bytes, name: name, mimeType: mimeFor(name))],
    names: [name],
    origin: origin ?? shareOrigin(context),
  );
}

/// Whether "open" means the default app (desktops) rather than the share sheet.
bool get opensInDefaultApp => _desktop;

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
Future<void> showComputerFile(BuildContext context, {required String computerId, required String path, String? name}) {
  return showAdaptiveSheet<void>(
    context: context,
    heightFactor: 0.85,
    contentPadsBottom: true,
    dialogMaxWidth: 760,
    dialogMaxHeight: 820,
    builder: (_) => FilePreview(computerId: computerId, path: path, name: name),
  );
}

bool get _desktop => !kIsWeb && (Platform.isMacOS || Platform.isWindows || Platform.isLinux);

class FilePreview extends ConsumerWidget {
  const FilePreview({super.key, required this.computerId, required this.path, this.name});

  /// The bot's computer; empty for chat media (`media:<id>` paths).
  final String computerId;
  final String path;

  /// The file's name when the path doesn't say it (chat media).
  final String? name;

  /// Chat media shows its own name (passed in), not its `media:` id.
  String get _name => name ?? fileNameOf(path);

  Future<void> _open(BuildContext context, Uint8List bytes, {Rect? origin}) => openFileBytes(context, _name, bytes, origin: origin);

  Future<void> _save(BuildContext context, Uint8List bytes) async {
    final name = _name;
    // The picker writes the file itself on every platform.
    final saved = await FilePicker.saveFile(fileName: name, bytes: bytes, mimeType: mimeFor(name));
    if (saved != null && context.mounted) showSuccess(context, context.l10n.savedFile(name));
  }

  Future<void> _share(BuildContext context, Uint8List bytes, {Rect? origin}) async {
    final name = _name;
    await shareFiles(
      [XFile.fromData(bytes, name: name, mimeType: mimeFor(name))],
      names: [name],
      origin: origin ?? shareOrigin(context),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = context.colorScheme;
    final name = _name;
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
                decoration: BoxDecoration(color: scheme.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(AppRadius.icon)),
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
                        if (!path.startsWith('media:')) path.startsWith('~/') || path.startsWith('/') ? path : 'workspace/$path',
                        if (bytes != null) formatBytes(bytes.length, context.l10n.localeName),
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
                  icon: const Icon(LucideIcons.x),
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
              Builder(
                builder: (button) => FilledButton.tonalIcon(
                  key: const Key('fileOpen'),
                  onPressed: bytes == null ? null : () => runGuarded(context, () => _open(context, bytes, origin: shareOrigin(button))),
                  icon: const Icon(LucideIcons.squareArrowOutUpRight, size: 18),
                  label: Text(_desktop ? l10n.openFile : l10n.shareFile),
                ),
              ),
              OutlinedButton.icon(
                key: const Key('fileSave'),
                onPressed: bytes == null ? null : () => runGuarded(context, () => _save(context, bytes)),
                icon: const Icon(LucideIcons.download, size: 18),
                label: Text(l10n.saveFile),
              ),
              if (_desktop)
                Builder(
                  builder: (button) => OutlinedButton.icon(
                    onPressed: bytes == null ? null : () => runGuarded(context, () => _share(context, bytes, origin: shareOrigin(button))),
                    icon: const Icon(LucideIcons.share, size: 18),
                    label: Text(l10n.shareFile),
                  ),
                ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: AsyncView(
            value: data,
            onRetry: () => ref.invalidate(computerFileProvider((computerId, path))),
            data: (bytes) => _Body(name: name, bytes: bytes, computerId: computerId, path: path, onOpen: () => _open(context, bytes)),
          ),
        ),
      ],
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.name, required this.bytes, required this.computerId, required this.path, required this.onOpen});
  final String name;
  final Uint8List bytes;
  final String computerId;
  final String path;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) => PreviewBody(
    name: name,
    bytes: bytes,
    computerId: computerId,
    path: path,
    onOpen: onOpen,
    unsupported: ([hint]) => _Unsupported(name: name, onOpen: onOpen, hint: hint),
  );
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
    action: GlowButton.icon(
      onPressed: onOpen,
      icon: const Icon(LucideIcons.squareArrowOutUpRight, size: 18),
      label: Text(_desktop ? context.l10n.openFile : context.l10n.shareFile),
    ),
  );
}
