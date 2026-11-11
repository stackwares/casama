// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'approval_resolved_event_payload.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ApprovalResolvedEventPayloadCWProxy {
  ApprovalResolvedEventPayload approvalId(String approvalId);

  ApprovalResolvedEventPayload decision(
    ApprovalResolvedEventPayloadDecisionEnum decision,
  );

  ApprovalResolvedEventPayload decidedBy(String? decidedBy);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ApprovalResolvedEventPayload(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ApprovalResolvedEventPayload(...).copyWith(id: 12, name: "My name")
  /// ```
  ApprovalResolvedEventPayload call({
    String approvalId,
    ApprovalResolvedEventPayloadDecisionEnum decision,
    String? decidedBy,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfApprovalResolvedEventPayload.copyWith(...)` or call `instanceOfApprovalResolvedEventPayload.copyWith.fieldName(value)` for a single field.
class _$ApprovalResolvedEventPayloadCWProxyImpl
    implements _$ApprovalResolvedEventPayloadCWProxy {
  const _$ApprovalResolvedEventPayloadCWProxyImpl(this._value);

  final ApprovalResolvedEventPayload _value;

  @override
  ApprovalResolvedEventPayload approvalId(String approvalId) =>
      call(approvalId: approvalId);

  @override
  ApprovalResolvedEventPayload decision(
    ApprovalResolvedEventPayloadDecisionEnum decision,
  ) => call(decision: decision);

  @override
  ApprovalResolvedEventPayload decidedBy(String? decidedBy) =>
      call(decidedBy: decidedBy);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ApprovalResolvedEventPayload(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ApprovalResolvedEventPayload(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ApprovalResolvedEventPayload call({
    Object? approvalId = const $CopyWithPlaceholder(),
    Object? decision = const $CopyWithPlaceholder(),
    Object? decidedBy = const $CopyWithPlaceholder(),
  }) {
    return ApprovalResolvedEventPayload(
      approvalId:
          approvalId == const $CopyWithPlaceholder() || approvalId == null
          ? _value.approvalId
          // ignore: cast_nullable_to_non_nullable
          : approvalId as String,
      decision: decision == const $CopyWithPlaceholder() || decision == null
          ? _value.decision
          // ignore: cast_nullable_to_non_nullable
          : decision as ApprovalResolvedEventPayloadDecisionEnum,
      decidedBy: decidedBy == const $CopyWithPlaceholder()
          ? _value.decidedBy
          // ignore: cast_nullable_to_non_nullable
          : decidedBy as String?,
    );
  }
}

extension $ApprovalResolvedEventPayloadCopyWith
    on ApprovalResolvedEventPayload {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfApprovalResolvedEventPayload.copyWith(...)` or `instanceOfApprovalResolvedEventPayload.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ApprovalResolvedEventPayloadCWProxy get copyWith =>
      _$ApprovalResolvedEventPayloadCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ApprovalResolvedEventPayload _$ApprovalResolvedEventPayloadFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('ApprovalResolvedEventPayload', json, ($checkedConvert) {
  $checkKeys(
    json,
    requiredKeys: const ['approval_id', 'decision', 'decided_by'],
  );
  final val = ApprovalResolvedEventPayload(
    approvalId: $checkedConvert('approval_id', (v) => v as String),
    decision: $checkedConvert(
      'decision',
      (v) => $enumDecode(_$ApprovalResolvedEventPayloadDecisionEnumEnumMap, v),
    ),
    decidedBy: $checkedConvert('decided_by', (v) => v as String?),
  );
  return val;
}, fieldKeyMap: const {'approvalId': 'approval_id', 'decidedBy': 'decided_by'});

Map<String, dynamic> _$ApprovalResolvedEventPayloadToJson(
  ApprovalResolvedEventPayload instance,
) => <String, dynamic>{
  'approval_id': instance.approvalId,
  'decision':
      _$ApprovalResolvedEventPayloadDecisionEnumEnumMap[instance.decision]!,
  'decided_by': instance.decidedBy,
};

const _$ApprovalResolvedEventPayloadDecisionEnumEnumMap = {
  ApprovalResolvedEventPayloadDecisionEnum.approved: 'approved',
  ApprovalResolvedEventPayloadDecisionEnum.denied: 'denied',
  ApprovalResolvedEventPayloadDecisionEnum.expired: 'expired',
};
