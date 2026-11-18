import 'package:material_ui/material_ui.dart';

import '../../../core/backend.dart';
import '../../files/file_preview.dart';
import '../media/attachment_view.dart';

final _link = RegExp(r'\[([^\]\n]{1,200})\]\(([^)\s]{1,500})\)');

/// Files on the bot's computer that a reply links to, as attachments: what the bot made shows up
/// right in the chat. Pictures show at their own shape, videos and sounds play in place, PDFs show
/// their first page, everything else is a file card; a tap opens the file preview (D-205).
///
/// A link to a file the reply already carries (a generated picture or video kept with the chat,
/// named like the copy on the computer) is skipped, so it doesn't show twice.
List<AttachmentRef> sharedFilesIn(String text, {List<AttachmentRef> alreadyShown = const []}) {
  final seen = <String>{};
  final shownNames = {for (final a in alreadyShown) a.name};
  return [
    for (final m in _link.allMatches(text))
      if (computerPathFromLink(m.group(2)!) case final path?
          when path.contains('.') && !shownNames.contains(path.split('/').last) && seen.add(path))
        AttachmentRef(
          path: path,
          name: path.split('/').last,
          mimeType: mimeFor(path.split('/').last),
          size: 0,
        ),
  ];
}

/// The most files shown under one reply.
const maxSharedFiles = 8;

final _image = RegExp(r'!\[([^\]\n]{0,200})\]\(([^)\s]{1,500})\)');
// What's left of a line that only pointed at files: bullets, emoji, bold, an optional short label
// ("PDF:", "Download it here:").
final _onlyLabel = RegExp(r'^[^\p{L}\p{N}]*([\p{L}\p{N}][\p{L}\p{N} ]{0,30}:)?[^\p{L}\p{N}]*$', unicode: true);

/// The reply's text as its bubble shows it once the files it links to show as cards under it: a
/// line that only listed a file ("📄 **PDF:** [x.pdf](workspace/x.pdf)") goes, a link inside a
/// sentence becomes its plain words, and a picture drawn inline goes (the card shows it). Copy and
/// read-aloud still use the full text. Falls back to [text] when nothing would be left.
String textWithoutSharedLinks(String text, {List<AttachmentRef> alreadyShown = const []}) {
  final shown = {
    for (final f in sharedFilesIn(text, alreadyShown: alreadyShown).take(maxSharedFiles)) f.path,
  };
  final shownNames = {for (final a in alreadyShown) a.name};
  bool isShown(String link) {
    final path = computerPathFromLink(link);
    return path != null && (shown.contains(path) || shownNames.contains(path.split('/').last));
  }

  if (shown.isEmpty && shownNames.isEmpty) return text;
  var inFence = false;
  final out = <String>[];
  for (final line in text.split('\n')) {
    if (line.trimLeft().startsWith('```') || line.trimLeft().startsWith('~~~')) inFence = !inFence;
    if (inFence) {
      out.add(line);
      continue;
    }
    var hit = false;
    var s = line.replaceAllMapped(_image, (m) {
      if (!isShown(m.group(2)!)) return m.group(0)!;
      hit = true;
      return '';
    });
    final words = s.replaceAllMapped(_link, (m) {
      if (!isShown(m.group(2)!)) return m.group(0)!;
      hit = true;
      return '\u0000';
    });
    if (!hit) {
      out.add(line);
      continue;
    }
    // Only labels and the file links themselves: the cards say it all.
    if (_onlyLabel.hasMatch(words.replaceAll('\u0000', ''))) continue;
    s = s.replaceAllMapped(_link, (m) => isShown(m.group(2)!) ? m.group(1)! : m.group(0)!);
    out.add(s);
  }
  final result = out.join('\n').replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();
  return result.isEmpty ? text : result;
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
      files: files.take(maxSharedFiles).toList(),
    ),
  );
}
