import '../../core/backend.dart';
import '../../core/remote_config.dart' show compareVersions;

/// Every kind the gallery lists, in the order its chips show.
const galleryKinds = [
  'theme',
  'scheme',
  'wallpaper',
  'skill',
  'app',
  'bot',
  'routine',
  'plugin',
  'set',
];

/// Kinds that change how this device looks; they apply here and are tracked locally.
const galleryLookKinds = {'theme', 'scheme', 'wallpaper'};

/// What the gallery shows on this app: no retired items, nothing this app can't draw, nothing
/// that needs a newer app ([appVersion] null while it loads: version gates wait for it).
List<GalleryItem> galleryVisible(
  Iterable<GalleryItem> items, {
  String? appVersion,
}) => [
  for (final item in items)
    if (!item.retired &&
        item.supported &&
        galleryKinds.contains(item.type) &&
        galleryAppAllows(item, appVersion))
      item,
];

/// Whether this app version can use [item] (its `min_app`).
bool galleryAppAllows(GalleryItem item, String? appVersion) {
  final min = item.minApp;
  if (min == null || min.isEmpty) return true;
  if (appVersion == null) return false;
  return compareVersions(appVersion, min) >= 0;
}

DateTime? _day(String? ymd) => ymd == null ? null : DateTime.tryParse(ymd);

/// Added in the last 30 days.
bool galleryIsNew(GalleryItem item, DateTime now) {
  final added = _day(item.added);
  if (added == null) return false;
  final age = DateTime(now.year, now.month, now.day).difference(added).inDays;
  return age >= 0 && age <= 30;
}

/// Whether "New" means anything here: not while more than half the catalog counts as new
/// (dates backfilled at launch put almost everything in the last 30 days). Same rule as the web.
bool galleryNewShown(List<GalleryItem> items, DateTime now) {
  if (items.isEmpty) return false;
  final fresh = items.where((i) => galleryIsNew(i, now)).length;
  return fresh * 2 <= items.length;
}

/// Whether [item] goes in the seasonal row today.
bool galleryInSeason(GalleryItem item, DateTime now) =>
    item.season?.contains(now) ?? false;

/// For routines, skills and bots: everything it needs is connected, or (needing nothing named)
/// it is about a connected app (its tags or id name one).
bool galleryWorksWith(GalleryItem item, Set<String> connected) {
  if (connected.isEmpty) return false;
  if (!const {'routine', 'skill', 'bot'}.contains(item.type)) return false;
  final apps = item.needs?.apps ?? const [];
  if (apps.isNotEmpty) return apps.every(connected.contains);
  final words = {
    ...item.tags.map((t) => t.toLowerCase()),
    ...item.id.split('-'),
  };
  return connected.any(words.contains);
}

/// The home rows, each already sorted and trimmed. Empty rows are hidden by the screen.
class GalleryRows {
  const GalleryRows({
    this.picks = const [],
    this.fresh = const [],
    this.trending = const [],
    this.mostUsed = const [],
    this.worksWith = const [],
    this.sets = const [],
    this.seasonal = const [],
  });

  final List<GalleryItem> picks;
  final List<GalleryItem> fresh;
  final List<GalleryItem> trending;
  final List<GalleryItem> mostUsed;
  final List<GalleryItem> worksWith;
  final List<GalleryItem> sets;
  final List<GalleryItem> seasonal;

  factory GalleryRows.from(
    List<GalleryItem> items, {
    required DateTime now,
    Set<String> connected = const {},
    int max = 12,
  }) {
    int byName(GalleryItem a, GalleryItem b) =>
        a.name.toLowerCase().compareTo(b.name.toLowerCase());

    // Picks take turns by kind, so the row shows the range.
    final featured = <String, List<GalleryItem>>{};
    for (final item in items.where((i) => i.featured && i.type != 'set')) {
      featured.putIfAbsent(item.type, () => []).add(item);
    }
    for (final list in featured.values) {
      list.sort((a, b) {
        // Items with a note why first: that's what makes a pick.
        final noted = (b.pick != null ? 1 : 0) - (a.pick != null ? 1 : 0);
        return noted != 0 ? noted : byName(a, b);
      });
    }
    final picks = <GalleryItem>[];
    for (var i = 0; picks.length < max; i++) {
      var added = false;
      for (final kind in galleryKinds) {
        final list = featured[kind];
        if (list != null && i < list.length && picks.length < max) {
          picks.add(list[i]);
          added = true;
        }
      }
      if (!added) break;
    }

    final fresh =
        !galleryNewShown(items, now)
              ? <GalleryItem>[]
              : items.where((i) => galleryIsNew(i, now)).toList()
          ..sort((a, b) {
            final d = (b.added ?? '').compareTo(a.added ?? '');
            return d != 0 ? d : byName(a, b);
          });

    final trending = items.where((i) => (i.stats?.trending ?? 0) > 0).toList()
      ..sort((a, b) => b.stats!.trending!.compareTo(a.stats!.trending!));

    const usedKinds = {'app', 'skill', 'wallpaper', 'theme'};
    final mostUsed =
        items
            .where(
              (i) =>
                  usedKinds.contains(i.type) && (i.stats?.installers ?? 0) > 0,
            )
            .toList()
          ..sort(
            (a, b) => b.stats!.installers!.compareTo(a.stats!.installers!),
          );

    final worksWith =
        items.where((i) => galleryWorksWith(i, connected)).toList()
          ..sort((a, b) {
            // Ones that name what they need first: those are the surest fit.
            final named =
                ((b.needs?.apps.isNotEmpty ?? false) ? 1 : 0) -
                ((a.needs?.apps.isNotEmpty ?? false) ? 1 : 0);
            return named != 0 ? named : byName(a, b);
          });

    final sets = items.where((i) => i.type == 'set').toList()
      ..sort((a, b) {
        if (a.featured != b.featured) return a.featured ? -1 : 1;
        return byName(a, b);
      });

    final seasonal = items.where((i) => galleryInSeason(i, now)).toList()
      ..sort(byName);

    List<GalleryItem> top(List<GalleryItem> l) => l.take(max).toList();
    return GalleryRows(
      picks: picks,
      fresh: top(fresh),
      trending: top(trending),
      mostUsed: top(mostUsed),
      worksWith: top(worksWith),
      sets: top(sets),
      seasonal: top(seasonal),
    );
  }
}

/// Words people type for the same thing. Each side finds the other. The gallery's search-words
/// list replaces it when the server sends one (D-372); this copy is the fallback.
const gallerySynonyms = <String, List<String>>{
  'mail': ['email', 'gmail', 'outlook', 'inbox'],
  'email': ['mail', 'gmail', 'outlook', 'inbox'],
  'inbox': ['email', 'mail'],
  'cal': ['calendar', 'schedule'],
  'calendar': ['cal', 'schedule', 'meeting', 'events'],
  'schedule': ['calendar', 'cal'],
  'meeting': ['meetings', 'calendar', 'notes'],
  'doc': ['docs', 'document', 'notion'],
  'docs': ['doc', 'document', 'notion'],
  'note': ['notes', 'notion', 'obsidian'],
  'notes': ['note', 'notion', 'obsidian'],
  'task': ['tasks', 'todo', 'linear', 'asana', 'jira'],
  'todo': ['task', 'tasks', 'checklist'],
  'chat': ['slack', 'messages', 'discord', 'teams'],
  'money': ['finance', 'budget', 'invoice', 'bills', 'expenses'],
  'finance': ['money', 'budget', 'accounting'],
  'code': ['github', 'developer', 'programming', 'coding'],
  'dev': ['developer', 'github', 'code'],
  'dark': ['night', 'black', 'midnight'],
  'light': ['bright', 'white', 'day'],
  'color': ['colour', 'scheme', 'palette'],
  'colour': ['color', 'scheme', 'palette'],
  'news': ['newsletter', 'headlines', 'digest'],
  'travel': ['trip', 'flight', 'flights', 'hotel'],
  'photo': ['image', 'picture', 'photos'],
  'write': ['writing', 'writer', 'blog', 'draft'],
  'social': ['twitter', 'linkedin', 'instagram', 'post'],
  'crm': ['sales', 'hubspot', 'salesforce', 'leads'],
  'sales': ['crm', 'leads', 'deals'],
  'sheet': ['sheets', 'spreadsheet', 'excel'],
  'spreadsheet': ['sheet', 'sheets', 'excel'],
  'study': ['student', 'school', 'learn'],
  'student': ['study', 'school', 'learn'],
  'health': ['fitness', 'workout', 'sleep'],
  'food': ['recipe', 'recipes', 'meal', 'cooking'],
};

/// [word] and everything it can mean, from [words] (the gallery's) or the built-in list.
Set<String> gallerySynonymsOf(String word, [Map<String, List<String>>? words]) {
  final list = words == null || words.isEmpty ? gallerySynonyms : words;
  final out = {word};
  out.addAll(list[word] ?? const []);
  for (final e in list.entries) {
    if (e.value.contains(word)) out.add(e.key);
  }
  return out;
}

String _hay(GalleryItem item) => [
  item.name,
  item.id,
  item.type,
  item.authorName,
  item.description ?? '',
  item.category ?? '',
  item.pick ?? '',
  ...item.tags,
  ...item.examples,
  ...?item.needs?.apps,
].join(' ').toLowerCase();

/// One search across every kind: every word must match (by itself or a synonym) the name, tags,
/// description, author, examples or what it needs. Name matches lead, then featured, then name.
List<GalleryItem> gallerySearch(
  List<GalleryItem> items,
  String query, {
  Map<String, List<String>>? searchWords,
}) {
  final words = query
      .toLowerCase()
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .toList();
  if (words.isEmpty) return items;
  final scored = <(GalleryItem, int)>[];
  for (final item in items) {
    final hay = _hay(item);
    final name = item.name.toLowerCase();
    var score = 0;
    var all = true;
    for (final word in words) {
      final forms = gallerySynonymsOf(word, searchWords);
      if (!forms.any(hay.contains)) {
        all = false;
        break;
      }
      if (name.contains(word)) {
        score += 3;
      } else if (forms.any(name.contains)) {
        score += 2;
      } else if (item.tags.any((t) => forms.contains(t.toLowerCase()))) {
        score += 1;
      }
    }
    if (all) scored.add((item, score));
  }
  scored.sort((a, b) {
    if (a.$2 != b.$2) return b.$2 - a.$2;
    if (a.$1.featured != b.$1.featured) return a.$1.featured ? -1 : 1;
    return a.$1.name.toLowerCase().compareTo(b.$1.name.toLowerCase());
  });
  return [for (final s in scored) s.$1];
}

/// Free to use, or uses a plan's credits.
enum GalleryPrice { free, plan }

/// The filters over the kind chips.
class GalleryFilter {
  const GalleryFilter({
    this.tag,
    this.price,
    this.selfHosted = false,
    this.computer = false,
  });

  /// A category or tag.
  final String? tag;
  final GalleryPrice? price;

  /// Only what works on a self-hosted server.
  final bool selfHosted;

  /// Only what needs a computer.
  final bool computer;

  bool get isEmpty => tag == null && price == null && !selfHosted && !computer;

  GalleryFilter copyWith({
    String? Function()? tag,
    GalleryPrice? Function()? price,
    bool? selfHosted,
    bool? computer,
  }) => GalleryFilter(
    tag: tag != null ? tag() : this.tag,
    price: price != null ? price() : this.price,
    selfHosted: selfHosted ?? this.selfHosted,
    computer: computer ?? this.computer,
  );

  bool matches(GalleryItem item) {
    final t = tag;
    if (t != null &&
        item.category != t &&
        !item.tags.any((x) => x.toLowerCase() == t)) {
      return false;
    }
    if (price != null && galleryPriceOf(item) != price) return false;
    if (selfHosted && !galleryWorksSelfHosted(item)) return false;
    if (computer && !(item.access?.computer ?? false)) return false;
    return true;
  }

  List<GalleryItem> apply(List<GalleryItem> items) => isEmpty
      ? items
      : [
          for (final i in items)
            if (matches(i)) i,
        ];
}

/// Looks and anything marked `credits: none` are free; the rest run on a plan's credits.
GalleryPrice galleryPriceOf(GalleryItem item) {
  if (galleryLookKinds.contains(item.type)) return GalleryPrice.free;
  return item.access?.credits == 'none' ? GalleryPrice.free : GalleryPrice.plan;
}

/// Self-hosted servers sign in to apps with their own address, which works for apps that
/// register themselves (`dcr`) or need no sign-in; apps tied to casama.ai's client document
/// (`cimd`) and items from extra catalogs that need them don't.
bool galleryWorksSelfHosted(GalleryItem item) {
  if (item.type == 'app') return item.document?['oauthClient'] != 'cimd';
  return true;
}

/// The categories and tags worth a filter chip: the most common ones across [items].
List<String> galleryTopTags(List<GalleryItem> items, {int max = 10}) {
  final counts = <String, int>{};
  for (final item in items) {
    final seen = <String>{
      if (item.category != null) item.category!,
      ...item.tags.map((t) => t.toLowerCase()),
    };
    for (final t in seen) {
      counts[t] = (counts[t] ?? 0) + 1;
    }
  }
  final list = counts.entries.where((e) => e.value > 1).toList()
    ..sort(
      (a, b) => b.value != a.value ? b.value - a.value : a.key.compareTo(b.key),
    );
  return [for (final e in list.take(max)) e.key];
}

/// An author's stable id: their handle, else their name as a slug.
String galleryAuthorKey(GalleryItem item) {
  final handle = item.authorHandle;
  if (handle != null && handle.isNotEmpty) return handle;
  return item.authorName
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
}

/// The items [set] lists, in its order, from [all] (ones not found are left out).
List<GalleryItem> gallerySetItems(GalleryItem set, List<GalleryItem> all) {
  final listed = set.document?['items'];
  if (listed is! List) return const [];
  return [
    for (final ref in listed)
      if (GalleryRef.fromJson(ref) case final GalleryRef r)
        if (all.where((i) => i.type == r.type && i.id == r.id).firstOrNull
            case final GalleryItem found)
          found,
  ];
}

/// "Used by 120 people · 96% of runs finish", or null with nothing to say.
({int? people, int? successPercent})? galleryStatsLine(GalleryStats? stats) {
  if (stats == null) return null;
  final people = stats.active ?? stats.installers;
  final success = stats.success == null ? null : (stats.success! * 100).round();
  if (people == null && success == null) return null;
  return (people: people, successPercent: success);
}
