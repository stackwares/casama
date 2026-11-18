import 'dart:convert';
import 'dart:io';

import 'package:casama_cli/casama_cli.dart';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:path/path.dart' as p;
import 'package:pinenacl/ed25519.dart';
import 'package:test/test.dart';

/// `casama gallery search|mirror` and `casama init --from-gallery` (D-315) against a stand-in
/// gallery served from memory.
void main() {
  late Directory tmp;
  late Map<String, List<int>> site;
  late List<String> fetched;

  final skillMd = utf8.encode(
    '---\nname: inbox-digest\ndescription: Summarize unread email.\n---\n\n# Inbox digest\n',
  );
  final skillItem = utf8.encode('{"name":"Inbox digest"}');
  final signing = SigningKey(seed: Uint8List.fromList(List.filled(32, 9)));
  final publicKey = base64.encode(signing.verifyKey.asTypedList);

  List<int> json(Object v) => utf8.encode(jsonEncode(v));

  /// Builds the stand-in catalog: item files, the derived JSON, manifest.json and manifest.sig.
  void build({bool sign = true}) {
    site = {
      'skills/inbox-digest/SKILL.md': skillMd,
      'skills/inbox-digest/item.json': skillItem,
    };
    site['index.json'] = json({
      'schema': 1,
      'items': [
        {
          'type': 'skill',
          'id': 'inbox-digest',
          'name': 'Inbox digest',
          'description': 'Summarize unread email into what needs a reply.',
          'tags': ['email'],
          'access': {
            'reads': ['email'],
          },
          'sha256': galleryHash({
            'skills/inbox-digest/SKILL.md': skillMd,
            'skills/inbox-digest/item.json': skillItem,
          }),
          'files': [
            'skills/inbox-digest/SKILL.md',
            'skills/inbox-digest/item.json',
          ],
        },
        {
          'type': 'theme',
          'id': 'forest-night',
          'name': 'Forest night',
          'tags': ['dark'],
        },
        {
          'type': 'skill',
          'id': 'old-mail',
          'name': 'Old mail digest',
          'retired': true,
        },
      ],
    });
    site['bots.json'] = json({
      'schema': 1,
      'items': [
        {
          'type': 'bot',
          'id': 'home-organizer',
          'name': 'Home organizer',
          'description': 'Keeps the household running.',
          'inputs': [
            {
              'key': 'household',
              'label': 'Who?',
              'type': 'text',
              'default': 'a household',
            },
            {
              'key': 'time',
              'label': 'When?',
              'type': 'time',
              'default': '07:30',
            },
          ],
          'document': {
            'description': 'Keeps the household running.',
            'mascot': 'lovey',
            'persona': 'You help {{household}} stay organised.',
            'autonomy': 'ask_risky',
            'skills': [
              {
                'name': 'lists',
                'description': 'Keep lists.',
                'body_md': 'Lists for {{household}}.',
              },
            ],
            'routines': [
              {
                'name': 'Morning plan',
                'instructions_md': 'Plan the day.',
                'schedule_cron': '{{time.minute}} {{time.hour}} * * *',
              },
            ],
          },
        },
      ],
    });
    site['plugins.json'] = json({
      'schema': 1,
      'items': [
        {
          'type': 'plugin',
          'id': 'hello',
          'name': 'Hello',
          'document': {
            'url': 'https://github.com/acme/tools/tree/main/plugins/hello',
            'commit': 'a' * 40,
          },
        },
      ],
    });
    final manifest = json({
      'schema': 1,
      'created': '2026-11-16',
      'files': {
        for (final f in ['index.json', 'bots.json', 'plugins.json'])
          f: sha256.convert(site[f]!).toString(),
      },
    });
    site['manifest.json'] = manifest;
    if (sign) {
      site['manifest.sig'] = utf8.encode(
        base64.encode(
          signing.sign(Uint8List.fromList(manifest)).signature.asTypedList,
        ),
      );
    }
  }

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('casama-gallery-test');
    fetched = [];
    build();
    galleryDeps = GalleryDeps()
      ..client = MockClient((req) async {
        fetched.add(req.url.toString());
        if (req.url.host == 'codeload.github.com') {
          expect(req.url.path, '/acme/tools/tar.gz/${'a' * 40}');
          return http.Response.bytes(
            gzip.encode(
              tar({
                'tools-aaaa/plugins/hello/plugin.json': '{"name":"hello"}',
                'tools-aaaa/plugins/hello/skills/hi/SKILL.md':
                    '---\nname: hi\n---\n',
                'tools-aaaa/plugins/other/plugin.json': '{}',
                'tools-aaaa/README.md': 'repo',
              }),
            ),
            200,
          );
        }
        final path = req.url.path.replaceFirst(RegExp(r'^/'), '');
        final body = site[path];
        return body == null
            ? http.Response('not found', 404)
            : http.Response.bytes(body, 200);
      });
  });
  tearDown(() => tmp.deleteSync(recursive: true));

  Future<(int, String, String)> run(List<String> args) async {
    final out = StringBuffer();
    final err = StringBuffer();
    final code = await runCli(
      [
        ...args,
        if (!args.contains('--gallery')) ...['--gallery', 'https://g.example/'],
      ],
      out: out,
      err: err,
      configDir: tmp,
    );
    return (code, out.toString(), err.toString());
  }

  test('galleryHash and signatures match the server and gallery/sign.mjs', () {
    // Same inputs as packages/domain galleryHash, and a signature made by Node's crypto.
    expect(
      galleryHash({
        'skills/a/SKILL.md': utf8.encode('hello é'),
        'skills/a/item.json': utf8.encode('{}'),
      }),
      '9611ef86f29b436e81b40c461397eaa440a240f9be076a4f9bc544f5c0978c6d',
    );
    const nodeKey = '6kpsY+KcUgq+9VB7Ey7F+ZVHdq6+vnuSQh7qaRRG0iw=';
    const nodeSig =
        '7OjpHRjo21fC9sF0GAVZiU3Gh+LN4V0s7Jnq6hiPHzM1lIwWnB7/nY9oQAukxIdpp+LkBXOxERD0qJgDAskWBA==';
    expect(
      verifyGallerySignature(nodeKey, utf8.encode('{"schema":1}\n'), nodeSig),
      isTrue,
    );
    expect(
      verifyGallerySignature(nodeKey, utf8.encode('{"schema":2}\n'), nodeSig),
      isFalse,
    );
    expect(verifyGallerySignature('short', [1], nodeSig), isFalse);
  });

  test(
    'search ranks matches, skips retired items and prints their pages',
    () async {
      final (code, out, _) = await run(['gallery', 'search', 'unread', 'mail']);
      expect(code, 0);
      expect(out, contains('skill/inbox-digest  Inbox digest'));
      expect(out, contains('https://g.example/i/skill/inbox-digest/'));
      expect(out, isNot(contains('old-mail')));

      final (_, js, _) = await run([
        '--json',
        'gallery',
        'search',
        '--type',
        'theme',
        'dark',
      ]);
      final rows = jsonDecode(js) as List;
      expect(rows.map((r) => r['id']), ['forest-night']);

      final (_, none, _) = await run(['gallery', 'search', 'zebra']);
      expect(none, contains('Nothing in the gallery matches'));
    },
  );

  test(
    'mirror downloads and verifies every file with the public key',
    () async {
      final dir = p.join(tmp.path, 'mirror');
      final (code, out, err) = await run([
        '--json',
        'gallery',
        'mirror',
        dir,
        '--public-key',
        publicKey,
      ]);
      expect(code, 0, reason: err);
      final result = jsonDecode(out) as Map;
      expect(result['signature_checked'], isTrue);
      expect(result['items'], 1);
      for (final f in [
        'index.json',
        'bots.json',
        'plugins.json',
        'manifest.json',
        'manifest.sig',
        'skills/inbox-digest/SKILL.md',
        'skills/inbox-digest/item.json',
      ]) {
        expect(File(p.join(dir, f)).readAsBytesSync(), site[f], reason: f);
      }
    },
  );

  test(
    'mirror without a key checks hashes and says it is not signature-checked',
    () async {
      final dir = p.join(tmp.path, 'm2');
      final (code, out, _) = await run([
        'gallery',
        'mirror',
        dir,
        '--json-only',
      ]);
      expect(code, 0);
      expect(out, contains('isn\'t signature-checked'));
      expect(
        File(p.join(dir, 'skills/inbox-digest/SKILL.md')).existsSync(),
        isFalse,
      );
    },
  );

  test('mirror refuses a bad signature, a missing one or a changed file, writing nothing', () async {
    final dir = p.join(tmp.path, 'bad');
    final other = base64.encode(
      SigningKey(seed: Uint8List.fromList(List.filled(32, 1)))
          .verifyKey
          .asTypedList,
    );
    var (code, _, err) = await run([
      'gallery',
      'mirror',
      dir,
      '--public-key',
      other,
    ]);
    expect(code, 1);
    expect(err, contains('signature_invalid'));

    build(sign: false);
    (code, _, err) = await run([
      'gallery',
      'mirror',
      dir,
      '--public-key',
      publicKey,
    ]);
    expect(err, contains('signature_missing'));

    build();
    site['bots.json'] = utf8.encode('{"schema":1,"items":[]}');
    (code, _, err) = await run([
      'gallery',
      'mirror',
      dir,
      '--public-key',
      publicKey,
    ]);
    expect(err, contains('hash_mismatch'));

    build();
    site['skills/inbox-digest/SKILL.md'] = utf8.encode('changed');
    (code, _, err) = await run(['gallery', 'mirror', dir]);
    expect(err, contains('hash_mismatch'));
    expect(Directory(dir).existsSync(), isFalse);
  });

  test('init --from-gallery bot/<id> writes a casama.bot template with defaults filled', () async {
    final dir = p.join(tmp.path, 'home');
    final (code, out, err) = await run([
      'init',
      '--from-gallery',
      'bot/home-organizer',
      dir,
    ]);
    expect(code, 0, reason: err);
    expect(out, contains('Started from gallery bot "home-organizer"'));
    final t = jsonDecode(
      File(p.join(dir, 'home-organizer.casama-bot.json')).readAsStringSync(),
    ) as Map;
    expect(t['format'], 'casama.bot');
    expect(t['version'], 1);
    expect(t['persona_md'], 'You help a household stay organised.');
    expect(t['avatar'], 'mascot:lovey');
    expect((t['skills'] as List).single['body_md'], 'Lists for a household.');
    expect((t['routines'] as List).single['schedule_cron'], '30 7 * * *');
    expect(File(p.join(dir, 'AGENTS.md')).existsSync(), isTrue);

    final (again, _, err2) = await run([
      'init',
      '--from-gallery=bot/home-organizer',
      dir,
    ]);
    expect(again, 1);
    expect(err2, contains('file_exists'));
  });

  test(
    'init --from-gallery plugin/<id> copies the folder at the reviewed commit',
    () async {
      final dir = p.join(tmp.path, 'hello');
      final (code, _, err) = await run([
        'init',
        '--from-gallery',
        'plugin/hello',
        dir,
      ]);
      expect(code, 0, reason: err);
      expect(
        File(p.join(dir, 'plugin.json')).readAsStringSync(),
        '{"name":"hello"}',
      );
      expect(File(p.join(dir, 'skills/hi/SKILL.md')).existsSync(), isTrue);
      expect(File(p.join(dir, 'README.md')).existsSync(), isFalse);

      final (missing, _, err2) = await run([
        'init',
        '--from-gallery',
        'bot/nope',
        dir,
      ]);
      expect(missing, 1);
      expect(err2, contains('gallery_item_not_found'));
      final (bad, _, _) = await run(['init', '--from-gallery', 'skill/x']);
      expect(bad, 64);
    },
  );

  test('rewriteFromGallery leaves other commands alone', () {
    expect(rewriteFromGallery(['init', 'bot', 'x']), ['init', 'bot', 'x']);
    expect(
      rewriteFromGallery(['--json', 'init', 'd', '--from-gallery', 'bot/a']),
      ['--json', 'init', 'from-gallery', 'bot/a', 'd'],
    );
  });
}

/// A ustar archive of [files] (path -> text).
List<int> tar(Map<String, String> files) {
  final out = BytesBuilder();
  for (final MapEntry(key: name, value: text) in files.entries) {
    final data = utf8.encode(text);
    final h = Uint8List(512);
    void put(int at, String s) =>
        h.setRange(at, at + s.length, ascii.encode(s));
    put(0, name);
    put(100, '0000644\x00');
    put(108, '0000000\x00');
    put(116, '0000000\x00');
    put(124, '${data.length.toRadixString(8).padLeft(11, '0')}\x00');
    put(136, '00000000000\x00');
    put(148, '        ');
    h[156] = 0x30;
    put(257, 'ustar\x0000');
    final sum = h.fold<int>(0, (a, b) => a + b);
    put(148, '${sum.toRadixString(8).padLeft(6, '0')}\x00 ');
    out
      ..add(h)
      ..add(data)
      ..add(Uint8List((512 - data.length % 512) % 512));
  }
  out.add(Uint8List(1024));
  return out.takeBytes();
}
