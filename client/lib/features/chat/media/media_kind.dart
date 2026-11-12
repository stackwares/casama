import 'dart:io' show Platform;
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../../core/backend.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../files/file_preview.dart';

/// How a file shows in a chat.
enum MediaKind { image, gif, svg, video, audio, pdf, office, other }

const _office = {
  'doc',
  'docx',
  'odt',
  'rtf',
  'xls',
  'xlsx',
  'ods',
  'ppt',
  'pptx',
  'odp',
};

String _extOf(String name) =>
    name.contains('.') ? name.split('.').last.toLowerCase() : '';

/// What kind of media a file is, from its MIME type when it says, else its name.
MediaKind mediaKindOf(String name, [String mime = '']) {
  final ext = _extOf(name);
  final m = mime.isEmpty || mime == 'application/octet-stream'
      ? mimeFor(name)
      : mime;
  if (m == 'image/svg+xml' || ext == 'svg') return MediaKind.svg;
  if (m == 'image/gif' || ext == 'gif') return MediaKind.gif;
  if (m.startsWith('image/')) return MediaKind.image;
  if (m.startsWith('video/')) return MediaKind.video;
  if (m.startsWith('audio/')) return MediaKind.audio;
  if (m == 'application/pdf' || ext == 'pdf') return MediaKind.pdf;
  if (_office.contains(ext)) return MediaKind.office;
  return MediaKind.other;
}

MediaKind attachmentKind(AttachmentRef a) => mediaKindOf(a.name, a.mimeType);

/// Pictures (photos, GIFs, drawings) show as pictures; everything else as a card or player.
bool isPicture(MediaKind k) =>
    k == MediaKind.image || k == MediaKind.gif || k == MediaKind.svg;

/// Widest and tallest a single picture shows in a chat.
const kChatImageMaxWidth = 280.0;
const kChatImageMaxHeight = 360.0;

/// The box a picture takes in a chat: its own shape, at most [kChatImageMaxWidth] wide (or the
/// space there is) and [kChatImageMaxHeight] tall, never upscaled past its pixels; 4:3 while its
/// size isn't known.
Size chatImageBox(double? width, double? height, double available) {
  final limit = math.min(kChatImageMaxWidth, available);
  if (width == null || height == null || width <= 0 || height <= 0) {
    return Size(limit, limit * 0.75);
  }
  var w = math.min(limit, width);
  var h = w * height / width;
  if (h > kChatImageMaxHeight) {
    h = kChatImageMaxHeight;
    w = h * width / height;
  }
  // Tiny icons stay tappable.
  return Size(math.max(w, 48), math.max(h, 48));
}

/// The official video player plays on phones, macOS and the web; elsewhere the system player does.
bool get inlineVideoSupported =>
    kIsWeb || Platform.isIOS || Platform.isAndroid || Platform.isMacOS;

/// Off under `flutter test`, where the PDF engine and media plugins aren't there.
final bool mediaPluginsAvailable =
    kIsWeb || !Platform.environment.containsKey('FLUTTER_TEST');

/// `1:05`, `12:30`, `1:02:03`.
String formatClock(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60);
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return h > 0 ? '$h:${m.toString().padLeft(2, '0')}:$s' : '$m:$s';
}

/// Every attachment's tappable root carries this key (tests tap it).
Key attachmentKey(String path) => Key('attachment-$path');

/// What to call an attachment: its file name, except chat media (generated images and videos
/// have generic names like `video.mp4`, D-205), which goes by its kind.
String attachmentLabel(AppLocalizations l10n, AttachmentRef a) {
  if (!a.isChatMedia) return a.name;
  return switch (attachmentKind(a)) {
    MediaKind.video => l10n.mediaKindVideo,
    MediaKind.audio => l10n.mediaKindAudio,
    MediaKind.pdf => l10n.mediaKindPdf,
    MediaKind.image || MediaKind.gif || MediaKind.svg => l10n.mediaKindImage,
    _ => a.name,
  };
}
