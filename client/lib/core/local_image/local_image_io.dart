import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';

Future<String> storeLocalImage(Uint8List bytes, String ext) async {
  final dir = Directory('${(await getApplicationSupportDirectory()).path}/wallpapers');
  await dir.create(recursive: true);
  final file = File('${dir.path}/${DateTime.now().millisecondsSinceEpoch}.$ext');
  await file.writeAsBytes(bytes);
  return file.path;
}

ImageProvider fileImage(String path) => FileImage(File(path));
