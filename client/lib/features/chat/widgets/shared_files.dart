import 'package:flutter/material.dart';

import '../../../core/backend.dart';
import '../../files/file_preview.dart';
import '../media/attachment_view.dart';

final _link = RegExp(r'\[([^\]\n]{1,200})\]\(([^)\s]{1,500})\)');

/// Files on the bot's computer that a reply links to, as attachments: what the bot made shows up
/// right in the chat. Pictures show at their own shape, videos and sounds play in place, PDFs show
/// their first page, everything else is a file card; a tap opens the file preview (D-205).
List<AttachmentRef> sharedFilesIn(String text) {
  final seen = <String>{};
  return [
    for (final m in _link.allMatches(text))
      if (computerPathFromLink(m.group(2)!) case final path? when path.contains('.') && seen.add(path))
        AttachmentRef(
          path: path,
          name: path.split('/').last,
          mimeType: mimeFor(path.split('/').last),
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
    child: MediaGroup(
      key: const Key('sharedFiles'),
      files: files.take(8).toList(),
    ),
  );
}
