// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_report_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CreateReportRequestCWProxy {
  CreateReportRequest targetKind(ReportTarget targetKind);

  CreateReportRequest targetId(String targetId);

  CreateReportRequest reason(ReportReason reason);

  CreateReportRequest note(String? note);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CreateReportRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CreateReportRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  CreateReportRequest call({
    ReportTarget targetKind,
    String targetId,
    ReportReason reason,
    String? note,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfCreateReportRequest.copyWith(...)` or call `instanceOfCreateReportRequest.copyWith.fieldName(value)` for a single field.
class _$CreateReportRequestCWProxyImpl implements _$CreateReportRequestCWProxy {
  const _$CreateReportRequestCWProxyImpl(this._value);

  final CreateReportRequest _value;

  @override
  CreateReportRequest targetKind(ReportTarget targetKind) =>
      call(targetKind: targetKind);

  @override
  CreateReportRequest targetId(String targetId) => call(targetId: targetId);

  @override
  CreateReportRequest reason(ReportReason reason) => call(reason: reason);

  @override
  CreateReportRequest note(String? note) => call(note: note);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CreateReportRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CreateReportRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  CreateReportRequest call({
    Object? targetKind = const $CopyWithPlaceholder(),
    Object? targetId = const $CopyWithPlaceholder(),
    Object? reason = const $CopyWithPlaceholder(),
    Object? note = const $CopyWithPlaceholder(),
  }) {
    return CreateReportRequest(
      targetKind:
          targetKind == const $CopyWithPlaceholder() || targetKind == null
          ? _value.targetKind
          // ignore: cast_nullable_to_non_nullable
          : targetKind as ReportTarget,
      targetId: targetId == const $CopyWithPlaceholder() || targetId == null
          ? _value.targetId
          // ignore: cast_nullable_to_non_nullable
          : targetId as String,
      reason: reason == const $CopyWithPlaceholder() || reason == null
          ? _value.reason
          // ignore: cast_nullable_to_non_nullable
          : reason as ReportReason,
      note: note == const $CopyWithPlaceholder()
          ? _value.note
          // ignore: cast_nullable_to_non_nullable
          : note as String?,
    );
  }
}

extension $CreateReportRequestCopyWith on CreateReportRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfCreateReportRequest.copyWith(...)` or `instanceOfCreateReportRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CreateReportRequestCWProxy get copyWith =>
      _$CreateReportRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateReportRequest _$CreateReportRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('CreateReportRequest', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['target_kind', 'target_id', 'reason']);
  final val = CreateReportRequest(
    targetKind: $checkedConvert(
      'target_kind',
      (v) => $enumDecode(_$ReportTargetEnumMap, v),
    ),
    targetId: $checkedConvert('target_id', (v) => v as String),
    reason: $checkedConvert(
      'reason',
      (v) => $enumDecode(_$ReportReasonEnumMap, v),
    ),
    note: $checkedConvert('note', (v) => v as String?),
  );
  return val;
}, fieldKeyMap: const {'targetKind': 'target_kind', 'targetId': 'target_id'});

Map<String, dynamic> _$CreateReportRequestToJson(
  CreateReportRequest instance,
) => <String, dynamic>{
  'target_kind': _$ReportTargetEnumMap[instance.targetKind]!,
  'target_id': instance.targetId,
  'reason': _$ReportReasonEnumMap[instance.reason]!,
  'note': ?instance.note,
};

const _$ReportTargetEnumMap = {
  ReportTarget.galleryItem: 'gallery_item',
  ReportTarget.galleryRequest: 'gallery_request',
  ReportTarget.packShare: 'pack_share',
  ReportTarget.bot: 'bot',
  ReportTarget.message: 'message',
  ReportTarget.user: 'user',
  ReportTarget.workspace: 'workspace',
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
