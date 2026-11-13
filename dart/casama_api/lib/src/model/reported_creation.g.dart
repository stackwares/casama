// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reported_creation.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ReportedCreationCWProxy {
  ReportedCreation id(String id);

  ReportedCreation orgId(String orgId);

  ReportedCreation orgName(String orgName);

  ReportedCreation title(String title);

  ReportedCreation kind(String kind);

  ReportedCreation reports(int reports);

  ReportedCreation reporters(int reporters);

  ReportedCreation lastReason(String lastReason);

  ReportedCreation takenDown(bool takenDown);

  ReportedCreation lastReportedAt(DateTime lastReportedAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ReportedCreation(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ReportedCreation(...).copyWith(id: 12, name: "My name")
  /// ```
  ReportedCreation call({
    String id,
    String orgId,
    String orgName,
    String title,
    String kind,
    int reports,
    int reporters,
    String lastReason,
    bool takenDown,
    DateTime lastReportedAt,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfReportedCreation.copyWith(...)` or call `instanceOfReportedCreation.copyWith.fieldName(value)` for a single field.
class _$ReportedCreationCWProxyImpl implements _$ReportedCreationCWProxy {
  const _$ReportedCreationCWProxyImpl(this._value);

  final ReportedCreation _value;

  @override
  ReportedCreation id(String id) => call(id: id);

  @override
  ReportedCreation orgId(String orgId) => call(orgId: orgId);

  @override
  ReportedCreation orgName(String orgName) => call(orgName: orgName);

  @override
  ReportedCreation title(String title) => call(title: title);

  @override
  ReportedCreation kind(String kind) => call(kind: kind);

  @override
  ReportedCreation reports(int reports) => call(reports: reports);

  @override
  ReportedCreation reporters(int reporters) => call(reporters: reporters);

  @override
  ReportedCreation lastReason(String lastReason) =>
      call(lastReason: lastReason);

  @override
  ReportedCreation takenDown(bool takenDown) => call(takenDown: takenDown);

  @override
  ReportedCreation lastReportedAt(DateTime lastReportedAt) =>
      call(lastReportedAt: lastReportedAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ReportedCreation(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ReportedCreation(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ReportedCreation call({
    Object? id = const $CopyWithPlaceholder(),
    Object? orgId = const $CopyWithPlaceholder(),
    Object? orgName = const $CopyWithPlaceholder(),
    Object? title = const $CopyWithPlaceholder(),
    Object? kind = const $CopyWithPlaceholder(),
    Object? reports = const $CopyWithPlaceholder(),
    Object? reporters = const $CopyWithPlaceholder(),
    Object? lastReason = const $CopyWithPlaceholder(),
    Object? takenDown = const $CopyWithPlaceholder(),
    Object? lastReportedAt = const $CopyWithPlaceholder(),
  }) {
    return ReportedCreation(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      orgId: orgId == const $CopyWithPlaceholder() || orgId == null
          ? _value.orgId
          // ignore: cast_nullable_to_non_nullable
          : orgId as String,
      orgName: orgName == const $CopyWithPlaceholder() || orgName == null
          ? _value.orgName
          // ignore: cast_nullable_to_non_nullable
          : orgName as String,
      title: title == const $CopyWithPlaceholder() || title == null
          ? _value.title
          // ignore: cast_nullable_to_non_nullable
          : title as String,
      kind: kind == const $CopyWithPlaceholder() || kind == null
          ? _value.kind
          // ignore: cast_nullable_to_non_nullable
          : kind as String,
      reports: reports == const $CopyWithPlaceholder() || reports == null
          ? _value.reports
          // ignore: cast_nullable_to_non_nullable
          : reports as int,
      reporters: reporters == const $CopyWithPlaceholder() || reporters == null
          ? _value.reporters
          // ignore: cast_nullable_to_non_nullable
          : reporters as int,
      lastReason:
          lastReason == const $CopyWithPlaceholder() || lastReason == null
          ? _value.lastReason
          // ignore: cast_nullable_to_non_nullable
          : lastReason as String,
      takenDown: takenDown == const $CopyWithPlaceholder() || takenDown == null
          ? _value.takenDown
          // ignore: cast_nullable_to_non_nullable
          : takenDown as bool,
      lastReportedAt:
          lastReportedAt == const $CopyWithPlaceholder() ||
              lastReportedAt == null
          ? _value.lastReportedAt
          // ignore: cast_nullable_to_non_nullable
          : lastReportedAt as DateTime,
    );
  }
}

extension $ReportedCreationCopyWith on ReportedCreation {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfReportedCreation.copyWith(...)` or `instanceOfReportedCreation.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ReportedCreationCWProxy get copyWith => _$ReportedCreationCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReportedCreation _$ReportedCreationFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'ReportedCreation',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'id',
            'org_id',
            'org_name',
            'title',
            'kind',
            'reports',
            'reporters',
            'last_reason',
            'taken_down',
            'last_reported_at',
          ],
        );
        final val = ReportedCreation(
          id: $checkedConvert('id', (v) => v as String),
          orgId: $checkedConvert('org_id', (v) => v as String),
          orgName: $checkedConvert('org_name', (v) => v as String),
          title: $checkedConvert('title', (v) => v as String),
          kind: $checkedConvert('kind', (v) => v as String),
          reports: $checkedConvert('reports', (v) => (v as num).toInt()),
          reporters: $checkedConvert('reporters', (v) => (v as num).toInt()),
          lastReason: $checkedConvert('last_reason', (v) => v as String),
          takenDown: $checkedConvert('taken_down', (v) => v as bool),
          lastReportedAt: $checkedConvert(
            'last_reported_at',
            (v) => DateTime.parse(v as String),
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'orgId': 'org_id',
        'orgName': 'org_name',
        'lastReason': 'last_reason',
        'takenDown': 'taken_down',
        'lastReportedAt': 'last_reported_at',
      },
    );

Map<String, dynamic> _$ReportedCreationToJson(ReportedCreation instance) =>
    <String, dynamic>{
      'id': instance.id,
      'org_id': instance.orgId,
      'org_name': instance.orgName,
      'title': instance.title,
      'kind': instance.kind,
      'reports': instance.reports,
      'reporters': instance.reporters,
      'last_reason': instance.lastReason,
      'taken_down': instance.takenDown,
      'last_reported_at': instance.lastReportedAt.toIso8601String(),
    };
