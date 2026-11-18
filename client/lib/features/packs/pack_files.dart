import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:casama_sdk/casama_sdk.dart' show PackExportFile, PackFileInput;

/// A pack holds at most 400 files and 10 MB (docs/PLUGINS-AND-PACKS-PLAN.md A.4).
const packMaxFiles = 400;
const packMaxBytes = 10 * 1024 * 1024;

/// Why a picked file can't be a pack.
enum PackFileProblem { unreadable, tooBig }

/// The files of a pack's .zip, ready to send as `files`. A zip made of one folder (as GitHub's
/// downloads are) is read from inside it; folders, macOS extras and hidden system files are left
/// out. Returns a [PackFileProblem] when the zip can't be read or is too big.
Object packFilesFromZip(Uint8List bytes) {
  final Archive archive;
  try {
    archive = ZipDecoder().decodeBytes(bytes);
  } catch (_) {
    return PackFileProblem.unreadable;
  }
  final entries = <(String, ArchiveFile)>[];
  for (final f in archive) {
    final name = f.name.replaceAll('\\', '/');
    if (!f.isFile || name.endsWith('/')) continue;
    if (name.startsWith('__MACOSX/') || name.split('/').last == '.DS_Store') continue;
    entries.add((name, f));
  }
  if (entries.isEmpty) return PackFileProblem.unreadable;
  // One top folder around everything: read from inside it.
  var prefix = '';
  final first = entries.first.$1;
  final slash = first.indexOf('/');
  if (slash > 0) {
    final candidate = first.substring(0, slash + 1);
    if (entries.every((e) => e.$1.startsWith(candidate))) prefix = candidate;
  }
  if (entries.length > packMaxFiles) return PackFileProblem.tooBig;
  var total = 0;
  final out = <PackFileInput>[];
  for (final (name, f) in entries) {
    final content = f.content;
    total += content.length;
    if (total > packMaxBytes) return PackFileProblem.tooBig;
    out.add(
      PackFileInput(
        path: name.substring(prefix.length),
        base64: base64Encode(content),
        // Any execute bit.
        executable: (f.mode & 0x49) != 0 ? true : null,
      ),
    );
  }
  return out;
}

/// A pack's exported files as a .zip, inside a folder named after the pack.
Uint8List packZip(String name, List<PackExportFile> files) {
  final folder = name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-').replaceAll(RegExp(r'^-+|-+$'), '');
  final archive = Archive();
  for (final f in files) {
    final bytes = f.base64 != null ? base64Decode(f.base64!) : utf8.encode(f.text ?? '');
    final file = ArchiveFile.bytes('${folder.isEmpty ? 'pack' : folder}/${f.path}', bytes);
    if (f.executable) file.mode = 0x1ed;
    archive.add(file);
  }
  return ZipEncoder().encodeBytes(archive);
}
