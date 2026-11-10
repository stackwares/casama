import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';

Future<String> storeLocalImage(Uint8List bytes, String ext) async => 'data:image/${ext == 'jpg' ? 'jpeg' : ext};base64,${base64Encode(bytes)}';

// The web has no files; anything else is treated as a web address.
ImageProvider fileImage(String path) => NetworkImage(path);
