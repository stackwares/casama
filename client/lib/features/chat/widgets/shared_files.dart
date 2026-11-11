import 'package:flutter/material.dart';

import '../../../core/backend.dart';
import '../../../theme/app_tokens.dart';
import '../../files/file_preview.dart';
import 'chat_widgets.dart' show AttachmentTile;

final _link = RegExp(r'\[([^\]\n]{1,200})\]\(([^)\s]{1,500})\)');

const _mime = {
  'png': 'image/png',
  'jpg': 'image/jpeg',
  'jpeg': 'image/jpeg',
  'gif': 'image/gif',
  'webp': 'image/webp',
  'pdf': 'application/pdf',
  'md': 'text/markdown',
  'txt': 'text/plain',
  'csv': 'text/csv',
  'json': 'application/json',
  'html': 'text/html',
  'zip': 'application/zip',
  'mp3': 'audio/mpeg',
  'mp4': 'video/mp4',
};

/// Files on the bot's computer that a reply links to, as attachments: what the bot made shows up
/// right in the chat. Images get a thumbnail; documents, data, code, archives and media get a
/// file card. Nothing is rendered or played inline beyond that; a tap opens the file preview.
List<AttachmentRef> sharedFilesIn(String text) {
  final seen = <String>{};
  return [
    for (final m in _link.allMatches(text))
      if (computerPathFromLink(m.group(2)!) case final path? when path.contains('.') && seen.add(path))
        AttachmentRef(
          path: path,
          name: path.split('/').last,
          mimeType: _mime[path.split('.').last.toLowerCase()] ?? 'application/octet-stream',
          size: 0,
        ),
  ];
}

/// The files a finished reply shares, under its text.
class SharedFiles extends StatelessWidget {
  const SharedFiles({super.key, required this.files});
  final List<AttachmentRef> files;

  @override
  Widget build(BuildContext context) => Align(
    alignment: AlignmentDirectional.centerStart,
    child: Wrap(
      key: const Key('sharedFiles'),
      spacing: AppSpace.xs,
      runSpacing: AppSpace.xs,
      children: [for (final f in files.take(8)) AttachmentTile(attachment: f)],
    ),
  );
}
