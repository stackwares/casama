import 'dart:io';

import 'package:kasama_cli/kasama_cli.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// Encrypted backups and retention (D-147). A stand-in `age` (same arguments) proves the files go
/// through age and back; the real age binary is used outside tests.
void main() {
  late Directory dir;
  late String age;
  setUp(() {
    dir = Directory.systemTemp.createTempSync('kasama-backups');
    // Fake age: "encrypts" by prefixing a header and reversing nothing; decrypts by stripping it.
    age = p.join(dir.path, 'fake-age');
    File(age).writeAsStringSync(r'''#!/bin/sh
out=""; dec=0; rec=""
while [ $# -gt 1 ]; do
  case "$1" in
    -o) out="$2"; shift 2 ;;
    -r) rec="$rec $2"; shift 2 ;;
    -i) shift 2 ;;
    -d) dec=1; shift ;;
    *) shift ;;
  esac
done
in="$1"
if [ $dec = 1 ]; then tail -n +2 "$in" > "$out"; else { echo "age-encryption.org/v1 to$rec"; cat "$in"; } > "$out"; fi
''');
    Process.runSync('chmod', ['+x', age]);
  });
  tearDown(() => dir.deleteSync(recursive: true));

  test('encrypts every file to the recipients and removes the plaintext; decrypts back', () async {
    final b = Directory(p.join(dir.path, '2026-11-10T08-00-00'))..createSync();
    File(p.join(b.path, 'postgres.dump')).writeAsStringSync('DUMP');
    File(p.join(b.path, 'env')).writeAsStringSync('JWT_SECRET=x');
    final done = await encryptFolder(b, ['age1recipient'], age: age);
    expect(done..sort(), ['env.age', 'postgres.dump.age']);
    expect(File(p.join(b.path, 'postgres.dump')).existsSync(), isFalse);
    expect(File(p.join(b.path, 'env.age')).readAsStringSync(), startsWith('age-encryption.org/v1 to age1recipient'));
    final out = Directory(p.join(dir.path, 'restored'));
    await decryptFolder(b, out, 'key.txt', age: age);
    expect(File(p.join(out.path, 'postgres.dump')).readAsStringSync().trim(), 'DUMP');
    expect(File(p.join(out.path, 'env')).readAsStringSync().trim(), 'JWT_SECRET=x');
  });

  test('needs a recipient, and says how to install age when missing', () async {
    final b = Directory(p.join(dir.path, 'x'))..createSync();
    File(p.join(b.path, 'f')).writeAsStringSync('1');
    expect(() => encryptFolder(b, const []), throwsA(isA<BackupError>()));
    expect(
      () => encryptFolder(b, ['age1x'], age: p.join(dir.path, 'no-such-age')),
      throwsA(isA<BackupError>().having((e) => e.message, 'message', contains('age is not installed'))),
    );
  });

  test('retention keeps the newest N and drops what is older than the day limit', () {
    final out = Directory(p.join(dir.path, 'out'))..createSync();
    for (final d in ['2026-11-01T00-00-00', '2026-11-05T00-00-00', '2026-11-08T00-00-00', '2026-11-09T00-00-00', '2026-11-10T00-00-00', 'notes']) {
      Directory(p.join(out.path, d)).createSync();
    }
    final now = DateTime.utc(2026, 11, 10, 12);
    expect(pruneBackups(out, keep: 3, now: now).map(p.basename).toList()..sort(), ['2026-11-01T00-00-00', '2026-11-05T00-00-00']);
    // Day limit alone: older than two days goes.
    expect(pruneBackups(out, keepDays: 2, now: now).map(p.basename).toList(), ['2026-11-08T00-00-00']);
    expect(out.listSync().map((e) => p.basename(e.path)).toList()..sort(), ['2026-11-09T00-00-00', '2026-11-10T00-00-00', 'notes']);
  });
}
