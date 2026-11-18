/// Gallery v2 shapes (D-315): what an item can touch, needs and asks, its history and stats, and
/// the installed list, requests board and submissions. Everything is optional for readers, so
/// older servers and catalogs parse.
library;

List<String> _strings(Object? v) => [
  for (final s in (v is List ? v : const [])) '$s',
];

int? _int(Object? v) => v is num ? v.toInt() : null;

Map<String, dynamic>? _map(Object? v) =>
    v is Map ? v.cast<String, dynamic>() : null;

/// A gallery item named by kind and id (`remix_of`, `replaced_by`, a set's items).
class GalleryRef {
  const GalleryRef(this.type, this.id);
  final String type;
  final String id;

  String get key => '$type/$id';

  static GalleryRef? fromJson(Object? j) {
    final m = _map(j);
    if (m == null || m['type'] is! String || m['id'] is! String) return null;
    return GalleryRef(m['type'] as String, m['id'] as String);
  }

  Map<String, Object?> toJson() => {'type': type, 'id': id};

  @override
  bool operator ==(Object other) =>
      other is GalleryRef && other.type == type && other.id == id;

  @override
  int get hashCode => Object.hash(type, id);
}

/// What an item can touch, in plain words.
class GalleryAccess {
  const GalleryAccess({
    this.reads = const [],
    this.writes = const [],
    this.runsCode = false,
    this.computer = false,
    this.credits,
  });

  final List<String> reads;
  final List<String> writes;
  final bool runsCode;
  final bool computer;

  /// `none`, `low`, `medium` or `high`.
  final String? credits;

  bool get isEmpty => reads.isEmpty && writes.isEmpty && !runsCode && !computer;

  static GalleryAccess? fromJson(Object? j) {
    final m = _map(j);
    if (m == null) return null;
    return GalleryAccess(
      reads: _strings(m['reads']),
      writes: _strings(m['writes']),
      runsCode: m['runs_code'] == true,
      computer: m['computer'] == true,
      credits: m['credits'] as String?,
    );
  }
}

/// Apps and skills a routine or bot needs before it works.
class GalleryNeeds {
  const GalleryNeeds({this.apps = const [], this.skills = const []});
  final List<String> apps;
  final List<String> skills;

  bool get isEmpty => apps.isEmpty && skills.isEmpty;

  static GalleryNeeds? fromJson(Object? j) {
    final m = _map(j);
    if (m == null) return null;
    return GalleryNeeds(
      apps: _strings(m['apps']),
      skills: _strings(m['skills']),
    );
  }
}

/// A question asked at install.
class GalleryInput {
  const GalleryInput({
    required this.key,
    required this.label,
    this.type = 'text',
    this.defaultValue,
    this.options = const [],
    this.help,
  });

  final String key;
  final String label;

  /// `text`, `choice`, `time` or `timezone`.
  final String type;
  final String? defaultValue;
  final List<String> options;
  final String? help;

  static GalleryInput? fromJson(Object? j) {
    final m = _map(j);
    if (m == null || m['key'] is! String) return null;
    return GalleryInput(
      key: m['key'] as String,
      label: m['label'] as String? ?? m['key'] as String,
      type: m['type'] as String? ?? 'text',
      defaultValue: m['default'] as String?,
      options: _strings(m['options']),
      help: m['help'] as String?,
    );
  }
}

/// One entry in an item's changelog.
class GalleryChange {
  const GalleryChange({
    required this.version,
    required this.date,
    required this.note,
    this.breaking = false,
  });
  final int version;
  final String date;
  final String note;
  final bool breaking;

  static GalleryChange? fromJson(Object? j) {
    final m = _map(j);
    if (m == null) return null;
    return GalleryChange(
      version: _int(m['version']) ?? 1,
      date: '${m['date'] ?? ''}',
      note: '${m['note'] ?? ''}',
      breaking: m['breaking'] == true,
    );
  }

  static List<GalleryChange> listOf(Object? v) => [
    for (final c in (v is List ? v : const []))
      if (fromJson(c) case final GalleryChange change) change,
  ];
}

/// When an item shows in the seasonal row: `MM-DD` to `MM-DD`, possibly wrapping the year end.
class GallerySeason {
  const GallerySeason(this.from, this.to);
  final String from;
  final String to;

  static GallerySeason? fromJson(Object? j) {
    final m = _map(j);
    if (m == null || m['from'] is! String || m['to'] is! String) return null;
    return GallerySeason(m['from'] as String, m['to'] as String);
  }

  /// Whether [day] falls in the season (inclusive at both ends).
  bool contains(DateTime day) {
    String two(int n) => n.toString().padLeft(2, '0');
    final today = '${two(day.month)}-${two(day.day)}';
    if (from.compareTo(to) <= 0) {
      return today.compareTo(from) >= 0 && today.compareTo(to) <= 0;
    }
    return today.compareTo(from) >= 0 || today.compareTo(to) <= 0;
  }
}

/// Aggregate use, as the server shares it (numbers below its thresholds are left out).
class GalleryStats {
  const GalleryStats({
    this.installers,
    this.trending,
    this.active,
    this.success,
  });
  final int? installers;
  final int? trending;
  final int? active;

  /// Share of runs that finished, 0..1.
  final double? success;

  bool get isEmpty =>
      installers == null &&
      trending == null &&
      active == null &&
      success == null;

  /// Reads the public shape (`installers`, `trending`, `active`, `success`) and the author's
  /// (`installers`, `installers_7d`, `active`, `runs_ok`, `runs_total`).
  static GalleryStats? fromJson(Object? j) {
    final m = _map(j);
    if (m == null) return null;
    final ok = _int(m['runs_ok']);
    final total = _int(m['runs_total']);
    return GalleryStats(
      installers: _int(m['installers']),
      trending: _int(m['trending'] ?? m['installers_7d']),
      active: _int(m['active'] ?? m['active_14d']),
      success:
          (m['success'] as num?)?.toDouble() ??
          (ok != null && total != null && total > 0 ? ok / total : null),
    );
  }
}

/// A skill's tests passed for this version.
class GalleryTested {
  const GalleryTested({required this.version, required this.date});
  final int version;
  final String date;

  static GalleryTested? fromJson(Object? j) {
    final m = _map(j);
    if (m == null) return null;
    return GalleryTested(
      version: _int(m['version']) ?? 1,
      date: '${m['date'] ?? ''}',
    );
  }
}

/// What an update adds to what an item can touch.
class GalleryAccessDiff {
  const GalleryAccessDiff({
    this.reads = const [],
    this.writes = const [],
    this.runsCode = false,
    this.computer = false,
  });
  final List<String> reads;
  final List<String> writes;
  final bool runsCode;
  final bool computer;

  bool get isEmpty => reads.isEmpty && writes.isEmpty && !runsCode && !computer;

  static GalleryAccessDiff fromJson(Object? j) {
    final m = _map(j) ?? const {};
    return GalleryAccessDiff(
      reads: _strings(m['reads']),
      writes: _strings(m['writes']),
      runsCode: m['runs_code'] == true,
      computer: m['computer'] == true,
    );
  }

  /// A 409 `access_changed` Problem's `errors`: `{path: "reads"|"writes", message: <added>}` and
  /// `{path: "runs_code"|"computer"|"breaking", message: "true"}` (breaking is read by
  /// [problemBreaking]).
  static GalleryAccessDiff fromProblemErrors(Object? errors) {
    final list = [
      for (final e in (errors is List ? errors : const []))
        if (_map(e) case final Map<String, dynamic> m) m,
    ];
    List<String> of(String path) => [
      for (final m in list)
        if (m['path'] == path) '${m['message'] ?? ''}',
    ];
    bool flag(String path) =>
        list.any((m) => m['path'] == path && '${m['message']}' == 'true');
    return GalleryAccessDiff(
      reads: of('reads'),
      writes: of('writes'),
      runsCode: flag('runs_code'),
      computer: flag('computer'),
    );
  }

  /// Whether a 409 `access_changed` Problem's `errors` say the update is breaking.
  static bool problemBreaking(Object? errors) =>
      errors is List &&
      errors.any((e) {
        final m = _map(e);
        return m?['path'] == 'breaking' && '${m?['message']}' == 'true';
      });
}

/// One workspace item installed from the gallery, with whether a newer version is out.
class GalleryInstalledItem {
  const GalleryInstalledItem({
    required this.type,
    required this.id,
    required this.name,
    required this.installedVersion,
    this.latestVersion,
    this.update = false,
    this.breaking = false,
    this.accessAdded = const GalleryAccessDiff(),
    this.retired = false,
    this.replacement,
    this.changelog = const [],
    this.installedAt,
    this.targetKind,
    this.targetId,
  });

  final String type;
  final String id;
  final String name;
  final int installedVersion;
  final int? latestVersion;
  final bool update;
  final bool breaking;
  final GalleryAccessDiff accessAdded;
  final bool retired;
  final GalleryRef? replacement;
  final List<GalleryChange> changelog;
  final DateTime? installedAt;

  /// The workspace thing it became: a skill, bot, routine, app or plugin and its id.
  final String? targetKind;
  final String? targetId;

  /// An update that asks first: access grew, or the change is breaking.
  bool get asksFirst => breaking || !accessAdded.isEmpty;

  /// The changelog entries newer than the installed copy.
  List<GalleryChange> get newChanges => [
    for (final c in changelog)
      if (c.version > installedVersion) c,
  ];

  factory GalleryInstalledItem.fromJson(Map<String, dynamic> j) {
    final target = _map(j['target']);
    return GalleryInstalledItem(
      type: j['type'] as String,
      id: j['id'] as String,
      name: j['name'] as String? ?? j['id'] as String,
      installedVersion: _int(j['installed_version']) ?? 1,
      latestVersion: _int(j['latest_version']),
      update: j['update'] == true,
      breaking: j['breaking'] == true,
      accessAdded: GalleryAccessDiff.fromJson(j['access_added']),
      retired: j['retired'] == true,
      replacement: GalleryRef.fromJson(j['replacement']),
      changelog: GalleryChange.listOf(j['changelog']),
      installedAt: DateTime.tryParse('${j['installed_at'] ?? ''}'),
      targetKind: target?['kind'] as String?,
      targetId: target?['id'] as String?,
    );
  }
}

/// An app or skill an install still needs, by id and name.
class GalleryMissing {
  const GalleryMissing(this.id, this.name);
  final String id;
  final String name;

  static List<GalleryMissing> listOf(Object? v) => [
    for (final m in (v is List ? v : const []))
      if (_map(m) case final Map<String, dynamic> e when e['id'] is String)
        GalleryMissing(
          e['id'] as String,
          e['name'] as String? ?? e['id'] as String,
        ),
  ];
}

/// One item of a starter set install and what became of it.
class GallerySetItemResult {
  const GallerySetItemResult({
    required this.type,
    required this.id,
    required this.status,
    this.installedKind,
    this.installedId,
    this.error,
  });

  final String type;
  final String id;

  /// `installed`, `approval_pending`, `skipped`, `failed`, or `device` (a look, applied on this
  /// device by the app).
  final String status;
  final String? installedKind;
  final String? installedId;
  final String? error;

  String get key => '$type/$id';

  /// Not added: skipped (already there, or a routine without a bot) or failed.
  bool get notAdded => status == 'skipped' || status == 'failed';

  static GallerySetItemResult? fromJson(Object? j) {
    final m = _map(j);
    if (m == null || m['type'] is! String || m['id'] is! String) return null;
    final installed = _map(m['installed']);
    return GallerySetItemResult(
      type: m['type'] as String,
      id: m['id'] as String,
      status: m['status'] as String? ?? 'failed',
      installedKind: installed?['kind'] as String?,
      installedId: installed?['id'] as String?,
      error: m['error'] as String?,
    );
  }
}

/// What an install did: what it became and what's still missing (apps to connect). One item
/// answers `{status, installed, approval_id, missing}`; a starter set `{items, missing}`.
class GalleryInstallResult {
  const GalleryInstallResult({
    this.installedKind,
    this.installedId,
    this.missingApps = const [],
    this.missingSkills = const [],
    this.pending = false,
    this.approvalId,
    this.items = const [],
  });

  final String? installedKind;
  final String? installedId;
  final List<GalleryMissing> missingApps;
  final List<GalleryMissing> missingSkills;

  /// The workspace asks an admin first; the install runs once they approve. For a set: any of
  /// its items waits.
  final bool pending;

  /// The approval an admin was asked for (one item only).
  final String? approvalId;

  /// A starter set's items, one result each; empty for a single item.
  final List<GallerySetItemResult> items;

  /// A set's looks, for the app to apply on this device.
  List<GallerySetItemResult> get deviceItems => [
    for (final i in items)
      if (i.status == 'device') i,
  ];

  /// A set's items that weren't added (skipped or failed).
  List<GallerySetItemResult> get notAdded => [
    for (final i in items)
      if (i.notAdded) i,
  ];

  factory GalleryInstallResult.fromJson(Map<String, dynamic> j) {
    final installed = _map(j['installed']);
    final missing = _map(j['missing']) ?? const {};
    final items = [
      for (final r in (j['items'] is List ? j['items'] as List : const []))
        if (GallerySetItemResult.fromJson(r) case final GallerySetItemResult i)
          i,
    ];
    return GalleryInstallResult(
      installedKind: installed?['kind'] as String?,
      installedId: installed?['id'] as String?,
      missingApps: GalleryMissing.listOf(missing['apps']),
      missingSkills: GalleryMissing.listOf(missing['skills']),
      pending:
          j['status'] == 'approval_pending' ||
          items.any((i) => i.status == 'approval_pending'),
      approvalId: j['approval_id'] as String?,
      items: items,
    );
  }
}

/// The server turned down an install's answers: an error per input key (400 `inputs_invalid`),
/// or `bot_id` when a routine or plugin was sent without its bot (400 `bot_required`).
class GalleryInputsInvalid implements Exception {
  const GalleryInputsInvalid(this.errors);
  final Map<String, String> errors;

  @override
  String toString() => errors.values.join(' ');
}

/// An update that grew what the item can touch (or is breaking) needs a yes first.
class GalleryAccessChanged implements Exception {
  const GalleryAccessChanged(this.added, {this.breaking = false});
  final GalleryAccessDiff added;
  final bool breaking;

  @override
  String toString() => 'access_changed';
}

/// One idea on the requests board.
class GalleryRequest {
  const GalleryRequest({
    required this.id,
    required this.kind,
    required this.title,
    this.details,
    this.status = 'open',
    this.votes = 0,
    this.voted = false,
    this.createdAt,
    this.doneItem,
    this.mine = false,
    this.similar = false,
  });

  final String id;
  final String kind;
  final String title;
  final String? details;

  /// `open`, `planned`, `done` or `declined`.
  final String status;
  final int votes;
  final bool voted;
  final DateTime? createdAt;

  /// The gallery item that answered it, once done.
  final GalleryRef? doneItem;

  /// The person asked for it.
  final bool mine;

  /// Creating it found this one with a similar title instead (and voted for it).
  final bool similar;

  GalleryRequest copyWith({int? votes, bool? voted, bool? similar}) =>
      GalleryRequest(
        id: id,
        kind: kind,
        title: title,
        details: details,
        status: status,
        votes: votes ?? this.votes,
        voted: voted ?? this.voted,
        createdAt: createdAt,
        doneItem: doneItem,
        mine: mine,
        similar: similar ?? this.similar,
      );

  factory GalleryRequest.fromJson(Map<String, dynamic> j) {
    final done = j['done_item_key'] as String?;
    final slash = done?.indexOf('/') ?? -1;
    return GalleryRequest(
      id: '${j['id']}',
      kind: j['kind'] as String? ?? '',
      title: j['title'] as String? ?? '',
      details: j['details'] as String?,
      status: j['status'] as String? ?? 'open',
      votes: _int(j['votes']) ?? 0,
      voted: j['voted'] == true,
      mine: j['mine'] == true,
      createdAt: DateTime.tryParse('${j['created_at'] ?? ''}'),
      doneItem: done != null && slash > 0
          ? GalleryRef(done.substring(0, slash), done.substring(slash + 1))
          : null,
    );
  }
}

/// Something the person sent to the gallery, and where its pull request stands.
class GallerySubmission {
  const GallerySubmission({
    required this.id,
    required this.type,
    required this.itemId,
    this.name,
    this.prUrl,
    this.status = 'open',
    this.createdAt,
  });

  final String id;
  final String type;

  /// The item's folder name in the gallery.
  final String itemId;
  final String? name;
  final String? prUrl;

  /// `open`, `merged`, `closed` or `failed` (the pull request couldn't be opened).
  final String status;
  final DateTime? createdAt;

  /// `<type>/<id>`.
  String get itemKey => '$type/$itemId';

  factory GallerySubmission.fromJson(Map<String, dynamic> j) =>
      GallerySubmission(
        id: '${j['id']}',
        type: j['type'] as String? ?? '',
        itemId: j['item_id'] as String? ?? '',
        name: j['name'] as String?,
        prUrl: j['pr_url'] as String?,
        status: j['status'] as String? ?? 'open',
        createdAt: DateTime.tryParse('${j['created_at'] ?? ''}'),
      );
}

/// One of the person's merged gallery items, with its full numbers.
class GalleryMyItem {
  const GalleryMyItem({
    required this.type,
    required this.id,
    required this.name,
    this.stats,
    this.reportsOpen = 0,
    this.version,
  });

  final String type;
  final String id;
  final String name;
  final GalleryStats? stats;
  final int reportsOpen;
  final int? version;

  factory GalleryMyItem.fromJson(Map<String, dynamic> j) => GalleryMyItem(
    type: j['type'] as String? ?? '',
    id: j['id'] as String? ?? '',
    name: j['name'] as String? ?? j['id'] as String? ?? '',
    stats: GalleryStats.fromJson(j['stats']),
    reportsOpen: _int(j['reports_open']) ?? 0,
    version: _int(j['version']),
  );
}

/// Someone asked to add a gallery item in a workspace that asks an admin first.
class WorkspaceGalleryApproval {
  const WorkspaceGalleryApproval({
    required this.id,
    required this.type,
    required this.itemId,
    required this.name,
    this.orgId,
    this.requestedBy,
    this.requestedByName,
    this.reason = '',
    this.status = 'pending',
    this.error,
    this.createdAt,
    this.decidedAt,
    this.pack = false,
  });

  final String id;
  final String? orgId;
  final String type;

  /// A pack (docs/PLUGINS-AND-PACKS-PLAN.md), which older apps see as a plugin.
  final bool pack;
  final String itemId;
  final String name;
  final String? requestedBy;
  final String? requestedByName;

  /// Why it asks first, as the workspace's rules put it.
  final String reason;

  /// `pending`, `approved`, `denied` or `failed` (approved, but the install didn't go through).
  final String status;
  final String? error;
  final DateTime? createdAt;
  final DateTime? decidedAt;

  /// `<type>/<id>`.
  String get key => '$type/$itemId';

  factory WorkspaceGalleryApproval.fromJson(Map<String, dynamic> j) =>
      WorkspaceGalleryApproval(
        id: '${j['id']}',
        orgId: j['org_id'] as String?,
        type: j['type'] as String? ?? '',
        itemId: j['item_id'] as String? ?? '',
        name: j['name'] as String? ?? j['item_id'] as String? ?? '',
        requestedBy: j['requested_by'] as String?,
        requestedByName: j['requested_by_name'] as String?,
        reason: j['reason'] as String? ?? '',
        status: j['status'] as String? ?? 'pending',
        error: j['error'] as String?,
        createdAt: DateTime.tryParse('${j['created_at'] ?? ''}'),
        decidedAt: DateTime.tryParse('${j['decided_at'] ?? ''}'),
        pack: j['pack'] == true,
      );
}
