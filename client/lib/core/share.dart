import 'package:flutter/widgets.dart';
import 'package:share_plus/share_plus.dart';

/// Where a share sheet should point: the widget that opened it. iPad and macOS show the sheet as a
/// popover anchored to this rectangle; without one it lands in a corner (or fails on iPad).
Rect? shareOrigin(BuildContext context) {
  final box = context.findRenderObject();
  if (box is RenderBox && box.attached && box.hasSize) return box.localToGlobal(Offset.zero) & box.size;
  final size = MediaQuery.maybeSizeOf(context);
  return size == null ? null : Rect.fromCenter(center: size.center(Offset.zero), width: 1, height: 1);
}

/// Shares files through the platform sheet, anchored at [origin] (see [shareOrigin]).
Future<void> shareFiles(List<XFile> files, {List<String>? names, Rect? origin}) =>
    SharePlus.instance.share(ShareParams(files: files, fileNameOverrides: names, sharePositionOrigin: origin));

/// Shares text through the platform sheet, anchored at [origin] (see [shareOrigin]).
Future<void> shareText(String text, {Rect? origin}) => SharePlus.instance.share(ShareParams(text: text, sharePositionOrigin: origin));
