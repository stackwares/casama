import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:pinenacl/ed25519.dart';

import 'commands_init.dart' show botAgentsMd;
import 'runner.dart';

/// The public gallery (D-315).
const defaultGalleryUrl = 'https://gallery.casama.ai';

/// Ed25519 public keys (base64 of the raw 32 bytes) of catalogs this CLI trusts without
/// `--public-key`, by base address. Other catalogs are checked by hash only unless a key is given.
const knownGalleryKeys = <String, String>{
  defaultGalleryUrl: '9cpyf5B04R5VEPqkryFMIe2qdSsg7vhgZRJMNOgc9cQ=',
};

/// The catalog files that hold items.
const galleryItemFiles = [
  'index.json',
  'apps.json',
  'bots.json',
  'routines.json',
  'plugins.json',
  'sets.json',
];

/// What the gallery commands call. Tests replace it; nothing else does.
class GalleryDeps {
  http.Client? client;
}

GalleryDeps galleryDeps = GalleryDeps();

/// `--gallery`, else CASAMA_GALLERY_URL, else the public gallery; no trailing slash.
String galleryBase(String? option) {
  final v =
      option ?? Platform.environment['CASAMA_GALLERY_URL'] ?? defaultGalleryUrl;
  return v.trim().replaceAll(RegExp(r'/+$'), '');
}

void _addGalleryOption(ArgParser parser) => parser.addOption(
  'gallery',
  help: 'Gallery address (or CASAMA_GALLERY_URL; default $defaultGalleryUrl).',
);

Future<T> _withClient<T>(Future<T> Function(http.Client c) body) async {
  final own = galleryDeps.client == null;
  final c = galleryDeps.client ?? http.Client();
  try {
    return await body(c);
  } finally {
    if (own) c.close();
  }
}

Future<Uint8List?> _get(
  http.Client c,
  String url, {
  bool required = true,
}) async {
  final http.Response r;
  try {
    r = await c.get(Uri.parse(url)).timeout(const Duration(seconds: 60));
  } on Exception catch (e) {
    throw CliError('network_error', 'Couldn\'t load $url: $e');
  }
  if (r.statusCode == 404 && !required) return null;
  if (r.statusCode != 200) {
    throw CliError(
      'gallery_unavailable',
      'Couldn\'t load $url (HTTP ${r.statusCode}).',
    );
  }
  return r.bodyBytes;
}

/// Every item record in the catalog's item files. A missing file is skipped.
Future<List<Map<String, dynamic>>> fetchGalleryItems(
  http.Client c,
  String base,
) async {
  final all = await Future.wait(
    galleryItemFiles.map((f) => _get(c, '$base/$f', required: false)),
  );
  final items = <Map<String, dynamic>>[];
  for (final bytes in all) {
    if (bytes == null) continue;
    final Object? doc;
    try {
      doc = jsonDecode(utf8.decode(bytes));
    } on FormatException {
      continue;
    }
    if (doc is! Map || doc['items'] is! List) continue;
    for (final i in doc['items'] as List) {
      if (i is Map<String, dynamic> &&
          i['id'] is String &&
          i['name'] is String &&
          i['type'] is String) {
        items.add(i);
      }
    }
  }
  if (items.isEmpty) {
    throw CliError('gallery_unavailable', 'No gallery items at $base.');
  }
  return items;
}

class GalleryCommand extends Command<int> {
  GalleryCommand(CliContext ctx) {
    addSubcommand(_GallerySearch(ctx));
    addSubcommand(_GalleryMirror(ctx));
  }
  @override
  String get name => 'gallery';
  @override
  String get description =>
      'Search the Casama gallery, or download a verified copy for an offline server.';
}

// --- search -----------------------------------------------------------------------------------

const _stop = {
  'a',
  'an',
  'and',
  'are',
  'as',
  'at',
  'be',
  'by',
  'can',
  'do',
  'for',
  'from',
  'how',
  'i', //
  'in',
  'is',
  'it',
  'me',
  'my',
  'of',
  'on',
  'or',
  'that',
  'the',
  'this',
  'to',
  'with',
  'you',
};

const _synonyms = {
  'mail': ['email', 'gmail', 'outlook'],
  'email': ['mail', 'gmail', 'inbox'],
  'cal': ['calendar'],
  'calendar': ['meeting', 'schedule'],
  'todo': ['task'],
  'money': ['finance', 'budget', 'bill'],
  'digest': ['brief', 'summary'],
  'summary': ['digest', 'summarize'],
  'look': ['theme', 'scheme', 'wallpaper'],
  'code': ['github', 'developer'],
};

/// Lowercase word stems without stop words (the same rule the MCP gallery_search uses).
List<String> galleryTokens(String text) => [
  for (final m in RegExp(r"[a-z0-9][a-z0-9'-]*").allMatches(text.toLowerCase()))
    m
        .group(0)!
        .replaceAll(RegExp(r"'s$"), '')
        .replaceAllMapped(
          RegExp(r'(ing|ed|es|s)$'),
          (x) =>
              m.group(0)!.length - x.group(0)!.length >= 4 ? '' : x.group(0)!,
        ),
].where((t) => t.length > 1 && !_stop.contains(t)).toList();

/// Names count most, then tags and category, then the description. Retired items never match.
List<Map<String, dynamic>> searchGallery(
  List<Map<String, dynamic>> items,
  String query, {
  Set<String>? types,
  int limit = 5,
}) {
  final words = galleryTokens(query).toSet();
  final weights = <String, double>{};
  for (final w in words) {
    weights[w] = 1;
    for (final s in _synonyms[w] ?? const <String>[]) {
      for (final t in galleryTokens(s)) {
        weights.putIfAbsent(t, () => 0.5);
      }
    }
  }
  final scored = <(Map<String, dynamic>, double)>[];
  for (final item in items) {
    if (item['retired'] == true) continue;
    if (types != null && types.isNotEmpty && !types.contains(item['type'])) {
      continue;
    }
    final name = galleryTokens(
      '${item['name']} ${(item['id'] as String).replaceAll('-', ' ')}',
    ).toSet();
    final tags = galleryTokens(
      [
        ...((item['tags'] as List?) ?? const []),
        item['category'] ?? '',
      ].join(' '),
    ).toSet();
    final desc = galleryTokens('${item['description'] ?? ''}').toSet();
    var score = words.isEmpty && types != null && types.isNotEmpty ? 0.1 : 0.0;
    weights.forEach((t, w) {
      score +=
          ((name.contains(t) ? 3 : 0) +
              (tags.contains(t) ? 2 : 0) +
              (desc.contains(t) ? 1 : 0)) *
          w;
    });
    if (score <= 0) continue;
    if (item['featured'] == true) score += 0.25;
    scored.add((item, score));
  }
  scored.sort((a, b) {
    final s = b.$2.compareTo(a.$2);
    return s != 0 ? s : '${a.$1['name']}'.compareTo('${b.$1['name']}');
  });
  return [for (final s in scored.take(limit)) s.$1];
}

class _GallerySearch extends KCommand {
  _GallerySearch(super.ctx) {
    argParser
      ..addMultiOption(
        'type',
        abbr: 't',
        help: 'Only these kinds.',
        allowed: const [
          'skill',
          'app',
          'routine',
          'bot',
          'plugin',
          'set',
          'theme',
          'scheme',
          'wallpaper',
        ],
      )
      ..addOption(
        'limit',
        abbr: 'l',
        defaultsTo: '10',
        help: 'At most this many.',
      );
    _addGalleryOption(argParser);
  }
  @override
  String get name => 'search';
  @override
  String get description =>
      'Find ready-made skills, apps, routines, bots, plugins, sets and looks.';
  @override
  String get invocation =>
      'casama gallery search <words> [--type skill] [--limit 10]';

  @override
  Future<int> run() async {
    final query = argResults!.rest.join(' ').trim();
    final types = (argResults!['type'] as List<String>).toSet();
    if (query.isEmpty && types.isEmpty) {
      throw UsageException('What are you looking for?', usage);
    }
    final limit = int.tryParse(argResults!['limit'] as String) ?? 10;
    final base = galleryBase(argResults!['gallery'] as String?);
    final items = await _withClient((c) => fetchGalleryItems(c, base));
    final hits = searchGallery(
      items,
      query,
      types: types,
      limit: limit.clamp(1, 50),
    );
    final rows = [
      for (final h in hits)
        {
          'type': h['type'],
          'id': h['id'],
          'name': h['name'],
          'description': h['description'] ?? '',
          if (h['access'] != null) 'access': h['access'],
          if (h['needs'] != null) 'needs': h['needs'],
          'url': '$base/i/${h['type']}/${h['id']}/',
        },
    ];
    if (rows.isEmpty) {
      return ctx.emit(
        rows,
        'Nothing in the gallery matches "$query". Request it in the app (Gallery > Request this) or build it: casama init skill',
      );
    }
    final human = StringBuffer();
    for (final r in rows) {
      human
        ..writeln('${r['type']}/${r['id']}  ${r['name']}')
        ..writeln('  ${r['description']}')
        ..writeln('  ${r['url']}');
    }
    human.write(
      'Start from a bot or plugin: casama init --from-gallery bot/<id> (or plugin/<id>)',
    );
    return ctx.emit(rows, human.toString());
  }
}

// --- mirror -----------------------------------------------------------------------------------

/// SHA-256 over sorted path + length + bytes: the gallery index's per-item `sha256`.
String galleryHash(Map<String, List<int>> files) {
  final paths = files.keys.toList()..sort();
  final all = BytesBuilder(copy: false);
  for (final path in paths) {
    final bytes = files[path]!;
    all
      ..add(utf8.encode(path))
      ..addByte(0)
      ..add(utf8.encode('${bytes.length}'))
      ..addByte(0)
      ..add(bytes);
  }
  return sha256.convert(all.takeBytes()).toString();
}

/// A path a catalog may name: relative, no `..`, plain characters.
final _safePath = RegExp(
  r'^[A-Za-z0-9_][A-Za-z0-9_.\-]*(/[A-Za-z0-9_][A-Za-z0-9_.\-]*)*$',
);

bool safeGalleryPath(String path) =>
    _safePath.hasMatch(path) && !path.split('/').contains('..');

/// Checks a base64 Ed25519 [signature] of [message] against a base64 raw 32-byte [publicKey].
bool verifyGallerySignature(
  String publicKey,
  List<int> message,
  String signature,
) {
  try {
    final key = base64.decode(publicKey.trim());
    final sig = base64.decode(signature.trim());
    if (key.length != 32 || sig.length != 64) return false;
    return VerifyKey(Uint8List.fromList(key)).verify(
      signature: Signature(Uint8List.fromList(sig)),
      message: Uint8List.fromList(message),
    );
  } catch (_) {
    return false;
  }
}

class _GalleryMirror extends KCommand {
  _GalleryMirror(super.ctx) {
    argParser
      ..addOption(
        'public-key',
        help:
            'The catalog\'s Ed25519 public key (base64), or CASAMA_GALLERY_PUBLIC_KEY. With a key, '
            'manifest.sig must be valid.',
      )
      ..addFlag(
        'json-only',
        negatable: false,
        help: 'Only the catalog files, not each item\'s files.',
      );
    _addGalleryOption(argParser);
  }
  @override
  String get name => 'mirror';
  @override
  String get description =>
      'Download a verified copy of the gallery into a folder, for servers without internet.';
  @override
  String get invocation =>
      'casama gallery mirror <directory> [--public-key <base64>] [--gallery <url>]';

  @override
  Future<int> run() async {
    final rest = argResults!.rest;
    if (rest.length != 1) throw UsageException('Give one directory.', usage);
    final dir = p.normalize(p.absolute(rest.single));
    final base = galleryBase(argResults!['gallery'] as String?);
    final given =
        (argResults!['public-key'] as String?) ??
        Platform.environment['CASAMA_GALLERY_PUBLIC_KEY'];
    final key = (given != null && given.trim().isNotEmpty)
        ? given.trim()
        : knownGalleryKeys[base];
    final jsonOnly = argResults!['json-only'] as bool;

    final written = <String, List<int>>{};
    var items = 0;
    await _withClient((c) async {
      final manifestBytes = (await _get(c, '$base/manifest.json'))!;
      final sigBytes = await _get(c, '$base/manifest.sig', required: false);
      if (key != null) {
        if (sigBytes == null) {
          throw CliError(
            'signature_missing',
            'The gallery at $base has no manifest.sig, so it can\'t be checked against the key. Nothing was written.',
          );
        }
        if (!verifyGallerySignature(
          key,
          manifestBytes,
          utf8.decode(sigBytes),
        )) {
          throw CliError(
            'signature_invalid',
            'manifest.sig doesn\'t match the public key. Nothing was written.',
          );
        }
      }
      final Object? manifest;
      try {
        manifest = jsonDecode(utf8.decode(manifestBytes));
      } on FormatException {
        throw CliError('manifest_invalid', 'manifest.json isn\'t JSON.');
      }
      final files = manifest is Map ? manifest['files'] : null;
      if (files is! Map || files.isEmpty) {
        throw CliError('manifest_invalid', 'manifest.json lists no files.');
      }
      for (final MapEntry(key: name, value: hash) in files.entries) {
        if (name is! String || !safeGalleryPath(name) || hash is! String) {
          throw CliError(
            'manifest_invalid',
            'manifest.json names a file it shouldn\'t: $name',
          );
        }
        final bytes = (await _get(c, '$base/$name'))!;
        if (sha256.convert(bytes).toString() != hash.toLowerCase()) {
          throw CliError(
            'hash_mismatch',
            '$name doesn\'t match manifest.json. Nothing was written.',
          );
        }
        written[name] = bytes;
      }
      if (!jsonOnly) {
        // Each record's files, checked against the record's sha256 (itself covered by the manifest).
        final records = <Map<String, dynamic>>[];
        for (final name in written.keys) {
          final doc = jsonDecode(utf8.decode(written[name]!));
          if (doc is Map && doc['items'] is List) {
            records.addAll(
              (doc['items'] as List).whereType<Map<String, dynamic>>(),
            );
          }
        }
        for (final r in records) {
          final paths = (r['files'] as List? ?? const [])
              .whereType<String>()
              .toList();
          if (paths.isEmpty) continue;
          final got = <String, List<int>>{};
          for (var i = 0; i < paths.length; i += 8) {
            final batch = paths.skip(i).take(8).toList();
            for (final path in batch) {
              if (!safeGalleryPath(path)) {
                throw CliError(
                  'manifest_invalid',
                  'A record names a file it shouldn\'t: $path',
                );
              }
            }
            final bytes = await Future.wait(
              batch.map((f) => _get(c, '$base/$f')),
            );
            for (var k = 0; k < batch.length; k++) {
              got[batch[k]] = bytes[k]!;
            }
          }
          final want = r['sha256'];
          if (want is String && galleryHash(got) != want) {
            throw CliError(
              'hash_mismatch',
              'The files of ${r['type']}/${r['id']} don\'t match the index. Nothing was written.',
            );
          }
          written.addAll(got);
          items++;
        }
      }
      written['manifest.json'] = manifestBytes;
      if (sigBytes != null) written['manifest.sig'] = sigBytes;
    });

    for (final MapEntry(key: rel, value: bytes) in written.entries) {
      final f = File(p.joinAll([dir, ...rel.split('/')]));
      f.parent.createSync(recursive: true);
      f.writeAsBytesSync(bytes);
    }
    final signed = key != null;
    final human = StringBuffer(
      'Mirrored ${written.length} files${jsonOnly ? '' : ' ($items items)'} from $base into $dir.\n',
    );
    human.writeln(
      signed ? 'manifest.sig is valid and every file matches manifest.json.' : 'Every file matches manifest.json, but the copy isn\'t signature-checked: pass --public-key to check manifest.sig.',
    );
    human.write(
      'Serve the folder over http and point the server at it: GALLERY_URL=http://<host>/ '
      '(https://docs.casama.ai/self-hosting/configuration).',
    );
    return ctx.emit({
      'gallery': base,
      'directory': dir,
      'files': written.length,
      'items': items,
      'signature_checked': signed,
    }, human.toString());
  }
}

// --- casama init --from-gallery ---------------------------------------------------------------

/// `casama init --from-gallery <type>/<id> [directory]` reaches this hidden subcommand.
List<String> rewriteFromGallery(List<String> args) {
  final at = args.indexOf('init');
  if (at == -1) return args;
  final out = [...args.take(at + 1)];
  final rest = args.skip(at + 1).toList();
  for (var i = 0; i < rest.length; i++) {
    final a = rest[i];
    if (a == '--from-gallery' && i + 1 < rest.length) {
      return [
        ...out,
        'from-gallery',
        rest[i + 1],
        ...rest.take(i),
        ...rest.skip(i + 2),
      ];
    }
    if (a.startsWith('--from-gallery=')) {
      return [
        ...out,
        'from-gallery',
        a.substring('--from-gallery='.length),
        ...rest.take(i),
        ...rest.skip(i + 1),
      ];
    }
  }
  return args;
}

/// Fills `{{key}}` with each input's default (and `{{time.hour}}`/`{{time.minute}}` from a time input).
String fillGalleryInputs(String text, List inputs) {
  final values = <String, String>{};
  for (final i in inputs.whereType<Map>()) {
    final k = i['key'];
    final d = i['default'];
    if (k is String && d is String) {
      values[k] = d;
      if (i['type'] == 'time') {
        final m = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(d);
        if (m != null) {
          values['$k.hour'] = '${int.parse(m.group(1)!)}';
          values['$k.minute'] = '${int.parse(m.group(2)!)}';
        }
      }
    }
  }
  return text.replaceAllMapped(
    RegExp(r'\{\{\s*([a-z][a-z0-9_]*(?:\.(?:hour|minute))?)\s*\}\}'),
    (m) => values[m.group(1)!] ?? m.group(0)!,
  );
}

/// A gallery bot's document as a `casama.bot` v1 template.
Map<String, Object?> botTemplateFromGallery(Map<String, dynamic> record) {
  final doc = (record['document'] as Map?) ?? const {};
  final inputs = (record['inputs'] as List?) ?? const [];
  String fill(Object? v) => fillGalleryInputs('${v ?? ''}', inputs);
  final autonomy = doc['autonomy'];
  final mascot = doc['mascot'];
  return {
    'format': 'casama.bot',
    'version': 1,
    'name': record['name'],
    'description': fill(doc['description'] ?? record['description']),
    'persona_md': fill(doc['persona']),
    'autonomy': autonomy is String ? autonomy : 'ask_risky',
    'avatar': mascot is String && mascot.isNotEmpty ? 'mascot:$mascot' : null,
    'skills': [
      for (final s in (doc['skills'] as List? ?? const []).whereType<Map>())
        {
          'name': s['name'],
          'description': fill(s['description']),
          'body_md': fill(s['body_md']),
        },
    ],
    'routines': [
      for (final r in (doc['routines'] as List? ?? const []).whereType<Map>())
        {
          'name': fill(r['name']),
          'instructions_md': fill(r['instructions_md']),
          'schedule_cron': fill(r['schedule_cron']),
        },
    ],
    'connections': const <Object>[],
  };
}

/// Files in a tar archive (regular files only), with pax and GNU long names.
Map<String, Uint8List> readTar(Uint8List bytes) {
  final out = <String, Uint8List>{};
  var pos = 0;
  String? longName;
  String field(int from, int len) {
    final raw = bytes.sublist(pos + from, pos + from + len);
    final end = raw.indexOf(0);
    return utf8.decode(
      end == -1 ? raw : raw.sublist(0, end),
      allowMalformed: true,
    );
  }

  while (pos + 512 <= bytes.length) {
    if (bytes.sublist(pos, pos + 512).every((b) => b == 0)) break;
    final sizeText = field(124, 12).trim();
    final size = sizeText.isEmpty ? 0 : int.parse(sizeText, radix: 8);
    final type = String.fromCharCode(
      bytes[pos + 156] == 0 ? 48 : bytes[pos + 156],
    );
    final prefix = field(345, 155);
    var name = field(0, 100);
    if (prefix.isNotEmpty) name = '$prefix/$name';
    final start = pos + 512;
    if (start + size > bytes.length) {
      throw const FormatException('The archive is cut short.');
    }
    final data = bytes.sublist(start, start + size);
    pos = start + ((size + 511) ~/ 512) * 512;
    if (type == 'x') {
      final m = RegExp(r'\d+ path=([^\n]*)\n')
          .firstMatch(utf8.decode(data, allowMalformed: true));
      if (m != null) longName = m.group(1);
      continue;
    }
    if (type == 'L') {
      longName = utf8.decode(data, allowMalformed: true).replaceAll('\x00', '');
      continue;
    }
    if (type == 'g') continue;
    if (longName != null) {
      name = longName;
      longName = null;
    }
    if (type == '0' || type == '7') out[name] = data;
  }
  return out;
}

class InitFromGalleryCommand extends KCommand {
  InitFromGalleryCommand(super.ctx) {
    argParser.addFlag(
      'force',
      negatable: false,
      help: 'Overwrite files that already exist.',
    );
    _addGalleryOption(argParser);
  }
  @override
  String get name => 'from-gallery';
  @override
  bool get hidden => true;
  @override
  String get description => 'Start from a gallery bot or plugin.';
  @override
  String get invocation =>
      'casama init --from-gallery <bot|plugin>/<id> [directory] [--force]';

  @override
  Future<int> run() async {
    final rest = argResults!.rest;
    if (rest.isEmpty || rest.length > 2) {
      throw UsageException(
        'Give bot/<id> or plugin/<id>, and at most one directory.',
        usage,
      );
    }
    final ref = RegExp(r'^(bot|plugin)/([a-z0-9][a-z0-9-]{0,62})$')
        .firstMatch(rest.first);
    if (ref == null) {
      throw UsageException(
        '"${rest.first}" isn\'t bot/<id> or plugin/<id>.',
        usage,
      );
    }
    final type = ref.group(1)!;
    final id = ref.group(2)!;
    final dir = p.normalize(p.absolute(rest.length == 2 ? rest[1] : id));
    final base = galleryBase(argResults!['gallery'] as String?);
    final force = argResults!['force'] as bool;

    final files = await _withClient((c) async {
      final listBytes = (await _get(c, '$base/${type}s.json'))!;
      final list = jsonDecode(utf8.decode(listBytes));
      final record = (list is Map ? list['items'] as List? : null)
          ?.whereType<Map<String, dynamic>>()
          .where((i) => i['type'] == type && i['id'] == id)
          .firstOrNull;
      if (record == null) {
        throw CliError(
          'gallery_item_not_found',
          'No $type called $id in the gallery. Find one with `casama gallery search`.',
        );
      }
      if (record['retired'] == true) {
        final next = record['replaced_by'];
        throw CliError(
          'gallery_item_retired',
          '$type/$id is retired.${next is Map ? ' Try ${next['type']}/${next['id']}.' : ''}',
        );
      }
      if (type == 'bot') {
        final file = '$id.casama-bot.json';
        return <String, List<int>>{
          file: utf8.encode(
            '${const JsonEncoder.withIndent('  ').convert(botTemplateFromGallery(record))}\n',
          ),
          'AGENTS.md': utf8.encode(botAgentsMd(file)),
        };
      }
      return _pluginFiles(c, record);
    });

    final existing = [
      for (final rel in files.keys)
        if (File(p.join(dir, rel)).existsSync()) rel,
    ];
    if (existing.isNotEmpty && !force) {
      throw CliError(
        'file_exists',
        'Already there: ${existing.join(', ')}. Nothing was written. Pass --force to overwrite.',
      );
    }
    for (final MapEntry(key: rel, value: bytes) in files.entries) {
      final f = File(p.joinAll([dir, ...rel.split('/')]));
      f.parent.createSync(recursive: true);
      f.writeAsBytesSync(bytes);
    }
    final shown = p.isWithin(p.current, dir) ? p.relative(dir) : dir;
    final steps = type == 'bot'
        ? [
            '1. Edit $shown/$id.casama-bot.json: persona_md, skills and routines.',
            '2. Import it: in the app, Bots > Import a bot; or POST /v1/bots/import.',
          ]
        : [
            '1. Check it: npx @casama/plugin-check $dir --strict',
            '2. Push it to your own public GitHub repository, then add it in a bot\'s settings > Plugins.',
          ];
    final human = StringBuffer('Started from gallery $type "$id" in $shown:\n');
    for (final rel in files.keys) {
      human.writeln('  ${existing.contains(rel) ? '~' : '+'} $rel');
    }
    human
      ..writeln()
      ..writeln('Next steps:');
    for (final s in steps) {
      human.writeln('  $s');
    }
    return ctx.emit({
      'kind': type,
      'id': id,
      'directory': dir,
      'files': files.keys.toList(),
      'overwritten': existing,
      'next_steps': steps,
    }, human.toString().trimRight());
  }

  /// The plugin's folder at its reviewed commit, from GitHub's archive of that commit.
  Future<Map<String, List<int>>> _pluginFiles(
    http.Client c,
    Map<String, dynamic> record,
  ) async {
    final doc = (record['document'] as Map?) ?? const {};
    final url = '${doc['url'] ?? ''}';
    final commit = '${doc['commit'] ?? ''}';
    final m = RegExp(
      r'^https://github\.com/([A-Za-z0-9_.-]+)/([A-Za-z0-9_.-]+?)(?:\.git)?(?:/tree/[^/]+(?:/(.+?))?)?/?$',
    ).firstMatch(url);
    if (m == null || !RegExp(r'^[0-9a-f]{40}$').hasMatch(commit)) {
      throw CliError(
        'plugin_source',
        'The gallery entry has no GitHub folder and commit to copy.',
      );
    }
    final folder = m.group(3) ?? '';
    final archive = await _get(
      c,
      'https://codeload.github.com/${m.group(1)}/${m.group(2)}/tar.gz/$commit',
    );
    if (archive!.length > 50 * 1024 * 1024) {
      throw CliError(
        'plugin_too_big',
        'The plugin\'s repository archive is over 50 MB.',
      );
    }
    final Map<String, Uint8List> entries;
    try {
      entries = readTar(Uint8List.fromList(gzip.decode(archive)));
    } on FormatException catch (e) {
      throw CliError(
        'plugin_source',
        'Couldn\'t read the repository archive: ${e.message}',
      );
    }
    final out = <String, List<int>>{};
    for (final MapEntry(key: name, value: bytes) in entries.entries) {
      // Every path starts with "<repo>-<commit>/".
      final slash = name.indexOf('/');
      if (slash == -1) continue;
      final inRepo = name.substring(slash + 1);
      final rel = folder.isEmpty
          ? inRepo
          : (inRepo.startsWith('$folder/')
                ? inRepo.substring(folder.length + 1)
                : null);
      if (rel == null || rel.isEmpty || !safeGalleryPath(rel)) continue;
      out[rel] = bytes;
    }
    if (!out.containsKey('plugin.json')) {
      throw CliError(
        'plugin_source',
        'There\'s no plugin.json at $url (commit $commit).',
      );
    }
    if (out.length > 1000) {
      throw CliError('plugin_too_big', 'The plugin has more than 1,000 files.');
    }
    return out;
  }
}
