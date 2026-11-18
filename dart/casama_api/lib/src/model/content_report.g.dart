// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'content_report.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ContentReportCWProxy {
  ContentReport id(String id);

  ContentReport targetKind(ReportTargetKind targetKind);

  ContentReport targetId(String targetId);

  ContentReport targetOrgId(String? targetOrgId);

  ContentReport targetOrgName(String? targetOrgName);

  ContentReport reason(ReportReason reason);

  ContentReport note(String? note);

  ContentReport snapshot(String? snapshot);

  ContentReport reporterEmail(String? reporterEmail);

  ContentReport sameTarget(int sameTarget);

  ContentReport status(ContentReportStatusEnum status);

  ContentReport createdAt(DateTime createdAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ContentReport(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ContentReport(...).copyWith(id: 12, name: "My name")
  /// ```
  ContentReport call({
    String id,
    ReportTargetKind targetKind,
    String targetId,
    String? targetOrgId,
    String? targetOrgName,
    ReportReason reason,
    String? note,
    String? snapshot,
    String? reporterEmail,
    int sameTarget,
    ContentReportStatusEnum status,
    DateTime createdAt,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfContentReport.copyWith(...)` or call `instanceOfContentReport.copyWith.fieldName(value)` for a single field.
class _$ContentReportCWProxyImpl implements _$ContentReportCWProxy {
  const _$ContentReportCWProxyImpl(this._value);

  final ContentReport _value;

  @override
  ContentReport id(String id) => call(id: id);

  @override
  ContentReport targetKind(ReportTargetKind targetKind) =>
      call(targetKind: targetKind);

  @override
  ContentReport targetId(String targetId) => call(targetId: targetId);

  @override
  ContentReport targetOrgId(String? targetOrgId) =>
      call(targetOrgId: targetOrgId);

  @override
  ContentReport targetOrgName(String? targetOrgName) =>
      call(targetOrgName: targetOrgName);

  @override
  ContentReport reason(ReportReason reason) => call(reason: reason);

  @override
  ContentReport note(String? note) => call(note: note);

  @override
  ContentReport snapshot(String? snapshot) => call(snapshot: snapshot);

  @override
  ContentReport reporterEmail(String? reporterEmail) =>
      call(reporterEmail: reporterEmail);

  @override
  ContentReport sameTarget(int sameTarget) => call(sameTarget: sameTarget);

  @override
  ContentReport status(ContentReportStatusEnum status) => call(status: status);

  @override
  ContentReport createdAt(DateTime createdAt) => call(createdAt: createdAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ContentReport(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ContentReport(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ContentReport call({
    Object? id = const $CopyWithPlaceholder(),
    Object? targetKind = const $CopyWithPlaceholder(),
    Object? targetId = const $CopyWithPlaceholder(),
    Object? targetOrgId = const $CopyWithPlaceholder(),
    Object? targetOrgName = const $CopyWithPlaceholder(),
    Object? reason = const $CopyWithPlaceholder(),
    Object? note = const $CopyWithPlaceholder(),
    Object? snapshot = const $CopyWithPlaceholder(),
    Object? reporterEmail = const $CopyWithPlaceholder(),
    Object? sameTarget = const $CopyWithPlaceholder(),
    Object? status = const $CopyWithPlaceholder(),
    Object? createdAt = const $CopyWithPlaceholder(),
  }) {
    return ContentReport(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      targetKind:
          targetKind == const $CopyWithPlaceholder() || targetKind == null
          ? _value.targetKind
          // ignore: cast_nullable_to_non_nullable
          : targetKind as ReportTargetKind,
      targetId: targetId == const $CopyWithPlaceholder() || targetId == null
          ? _value.targetId
          // ignore: cast_nullable_to_non_nullable
          : targetId as String,
      targetOrgId: targetOrgId == const $CopyWithPlaceholder()
          ? _value.targetOrgId
          // ignore: cast_nullable_to_non_nullable
          : targetOrgId as String?,
      targetOrgName: targetOrgName == const $CopyWithPlaceholder()
          ? _value.targetOrgName
          // ignore: cast_nullable_to_non_nullable
          : targetOrgName as String?,
      reason: reason == const $CopyWithPlaceholder() || reason == null
          ? _value.reason
          // ignore: cast_nullable_to_non_nullable
          : reason as ReportReason,
      note: note == const $CopyWithPlaceholder()
          ? _value.note
          // ignore: cast_nullable_to_non_nullable
          : note as String?,
      snapshot: snapshot == const $CopyWithPlaceholder()
          ? _value.snapshot
          // ignore: cast_nullable_to_non_nullable
          : snapshot as String?,
      reporterEmail: reporterEmail == const $CopyWithPlaceholder()
          ? _value.reporterEmail
          // ignore: cast_nullable_to_non_nullable
          : reporterEmail as String?,
      sameTarget:
          sameTarget == const $CopyWithPlaceholder() || sameTarget == null
          ? _value.sameTarget
          // ignore: cast_nullable_to_non_nullable
          : sameTarget as int,
      status: status == const $CopyWithPlaceholder() || status == null
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as ContentReportStatusEnum,
      createdAt: createdAt == const $CopyWithPlaceholder() || createdAt == null
          ? _value.createdAt
          // ignore: cast_nullable_to_non_nullable
          : createdAt as DateTime,
    );
  }
}

extension $ContentReportCopyWith on ContentReport {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfContentReport.copyWith(...)` or `instanceOfContentReport.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ContentReportCWProxy get copyWith => _$ContentReportCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ContentReport _$ContentReportFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'ContentReport',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'id',
            'target_kind',
            'target_id',
            'target_org_id',
            'target_org_name',
            'reason',
            'note',
            'snapshot',
            'reporter_email',
            'same_target',
            'status',
            'created_at',
          ],
        );
        final val = ContentReport(
          id: $checkedConvert('id', (v) => v as String),
          targetKind: $checkedConvert(
            'target_kind',
            (v) => $enumDecode(_$ReportTargetKindEnumMap, v),
          ),
          targetId: $checkedConvert('target_id', (v) => v as String),
          targetOrgId: $checkedConvert('target_org_id', (v) => v as String?),
          targetOrgName: $checkedConvert(
            'target_org_name',
            (v) => v as String?,
          ),
          reason: $checkedConvert(
            'reason',
            (v) => $enumDecode(_$ReportReasonEnumMap, v),
          ),
          note: $checkedConvert('note', (v) => v as String?),
          snapshot: $checkedConvert('snapshot', (v) => v as String?),
          reporterEmail: $checkedConvert('reporter_email', (v) => v as String?),
          sameTarget: $checkedConvert('same_target', (v) => (v as num).toInt()),
          status: $checkedConvert(
            'status',
            (v) => $enumDecode(_$ContentReportStatusEnumEnumMap, v),
          ),
          createdAt: $checkedConvert(
            'created_at',
            (v) => DateTime.parse(v as String),
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'targetKind': 'target_kind',
        'targetId': 'target_id',
        'targetOrgId': 'target_org_id',
        'targetOrgName': 'target_org_name',
        'reporterEmail': 'reporter_email',
        'sameTarget': 'same_target',
        'createdAt': 'created_at',
      },
    );

Map<String, dynamic> _$ContentReportToJson(ContentReport instance) =>
    <String, dynamic>{
      'id': instance.id,
      'target_kind': _$ReportTargetKindEnumMap[instance.targetKind]!,
      'target_id': instance.targetId,
      'target_org_id': instance.targetOrgId,
      'target_org_name': instance.targetOrgName,
      'reason': _$ReportReasonEnumMap[instance.reason]!,
      'note': instance.note,
      'snapshot': instance.snapshot,
      'reporter_email': instance.reporterEmail,
      'same_target': instance.sameTarget,
      'status': _$ContentReportStatusEnumEnumMap[instance.status]!,
      'created_at': instance.createdAt.toIso8601String(),
    };

const _$ReportTargetKindEnumMap = {
  ReportTargetKind.galleryItem: 'gallery_item',
  ReportTargetKind.bot: 'bot',
  ReportTargetKind.message: 'message',
  ReportTargetKind.user: 'user',
  ReportTargetKind.workspace: 'workspace',
};

const _$ReportReasonEnumMap = {
  ReportReason.spam: 'spam',
  ReportReason.sexual: 'sexual',
  ReportReason.violence: 'violence',
  ReportReason.harassment: 'harassment',
  ReportReason.illegal: 'illegal',
  ReportReason.impersonation: 'impersonation',
  ReportReason.other: 'other',
};

const _$ContentReportStatusEnumEnumMap = {
  ContentReportStatusEnum.open: 'open',
  ContentReportStatusEnum.actioned: 'actioned',
  ContentReportStatusEnum.dismissed: 'dismissed',
};
