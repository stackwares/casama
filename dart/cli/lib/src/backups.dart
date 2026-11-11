import 'dart:io';

import 'package:path/path.dart' as p;

/// Encrypted backups and retention for `casama selfhost backup` (D-147). Encryption uses age
/// (https://age-encryption.org): each file is encrypted to the given recipients (age1… public keys
/// or ssh keys) and the plaintext removed; restoring decrypts with an identity file.
class BackupError implements Exception {
  BackupError(this.message);
  final String message;
  @override
  String toString() => message;
}

typedef Runner = Future<ProcessResult> Function(String exe, List<String> args);
Future<ProcessResult> _defaultRun(String exe, List<String> args) => Process.run(exe, args);

/// Encrypts every file in [dir] to [recipients] with age (file → file.age) and removes the plaintext.
Future<List<String>> encryptFolder(Directory dir, List<String> recipients, {String age = 'age', Runner run = _defaultRun}) async {
  if (recipients.isEmpty) throw BackupError('Give at least one --recipient (an age public key, age1…).');
  final done = <String>[];
  for (final f in dir.listSync().whereType<File>().where((f) => !f.path.endsWith('.age'))) {
    final ProcessResult r;
    try {
      r = await run(age, [
        for (final rc in recipients) ...['-r', rc],
        '-o',
        '${f.path}.age',
        f.path,
      ]);
    } on ProcessException {
      throw BackupError('age is not installed. Install it (brew install age, apt install age, or https://age-encryption.org) and try again.');
    }
    if (r.exitCode != 0) throw BackupError('age could not encrypt ${p.basename(f.path)}: ${r.stderr}');
    f.deleteSync();
    done.add('${p.basename(f.path)}.age');
  }
  return done;
}

/// Decrypts every .age file in [dir] into [into] with an age identity file.
Future<void> decryptFolder(Directory dir, Directory into, String identity, {String age = 'age', Runner run = _defaultRun}) async {
  into.createSync(recursive: true);
  for (final f in dir.listSync().whereType<File>()) {
    final name = p.basename(f.path);
    if (!name.endsWith('.age')) {
      f.copySync(p.join(into.path, name));
      continue;
    }
    final ProcessResult r;
    try {
      r = await run(age, ['-d', '-i', identity, '-o', p.join(into.path, name.substring(0, name.length - 4)), f.path]);
    } on ProcessException {
      throw BackupError('age is not installed, so encrypted backups cannot be read.');
    }
    if (r.exitCode != 0) throw BackupError('age could not decrypt $name (wrong identity?): ${r.stderr}');
  }
}

/// Retention: keeps the newest [keep] backup folders and those newer than [keepDays]; returns removed paths.
List<String> pruneBackups(Directory out, {int? keep, int? keepDays, DateTime? now}) {
  if (!out.existsSync() || (keep == null && keepDays == null)) return const [];
  final stamp = RegExp(r'^\d{4}-\d{2}-\d{2}T\d{2}-\d{2}-\d{2}$');
  final folders = out.listSync().whereType<Directory>().where((d) => stamp.hasMatch(p.basename(d.path))).toList()..sort((a, b) => p.basename(b.path).compareTo(p.basename(a.path)));
  final cutoff = keepDays == null ? null : (now ?? DateTime.now().toUtc()).subtract(Duration(days: keepDays));
  final removed = <String>[];
  for (var i = 0; i < folders.length; i++) {
    final name = p.basename(folders[i].path);
    final when = DateTime.parse('${name.substring(0, 10)}T${name.substring(11).replaceAll('-', ':')}Z');
    final byCount = keep != null && i >= keep;
    final byAge = cutoff != null && when.isBefore(cutoff);
    // A folder goes when it's outside every limit that was given.
    final drop = (keep == null || byCount) && (cutoff == null || byAge);
    if (drop) {
      folders[i].deleteSync(recursive: true);
      removed.add(folders[i].path);
    }
  }
  return removed;
}
