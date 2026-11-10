import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';

import 'local_image/local_image_web.dart' if (dart.library.io) 'local_image/local_image_io.dart' as impl;

/// Pictures the person picked (wallpaper photos): kept as a file in the app's own folder on
/// devices, and as a data: URI on the web, which has no files.
Future<String> storeLocalImage(Uint8List bytes, {String ext = 'jpg'}) => impl.storeLocalImage(bytes, ext);

final _memory = <String, MemoryImage>{};

/// An image provider for a stored picture or a web address.
ImageProvider imageProviderFor(String source) {
  if (source.startsWith('http://') || source.startsWith('https://')) return NetworkImage(source);
  if (source.startsWith('data:')) {
    // One MemoryImage per URI, so the image cache recognises it on every page.
    return _memory.putIfAbsent(source, () {
      if (_memory.length > 8) _memory.clear();
      return MemoryImage(base64Decode(source.substring(source.indexOf(',') + 1)));
    });
  }
  return impl.fileImage(source);
}
