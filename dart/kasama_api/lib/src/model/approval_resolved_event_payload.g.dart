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

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ApprovalResolvedEventPayload(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ApprovalResolvedEventPayload(...).copyWith(id: 12, name: "My name")
  /// ````
  ApprovalResolvedEventPayload call({
    String approvalId,
    ApprovalResolvedEventPayloadDecisionEnum decision,
    String? decidedBy,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfApprovalResolvedEventPayload.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfApprovalResolvedEventPayload.copyWith.fieldName(...)`
class _$ApprovalResolvedEventPayloadCWProxyImpl
    implements _$ApprovalResolvedEventPayloadCWProxy {
  const _$ApprovalResolvedEventPayloadCWProxyImpl(this._value);

  final ApprovalResolvedEventPayload _value;

  @override
  ApprovalResolvedEventPayload approvalId(String approvalId) =>
      this(approvalId: approvalId);

  @override
  ApprovalResolvedEventPayload decision(
    ApprovalResolvedEventPayloadDecisionEnum decision,
  ) => this(decision: decision);

  @override
  ApprovalResolvedEventPayload decidedBy(String? decidedBy) =>
      this(decidedBy: decidedBy);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ApprovalResolvedEventPayload(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ApprovalResolvedEventPayload(...).copyWith(id: 12, name: "My name")
  /// ````
  ApprovalResolvedEventPayload call({
    Object? approvalId = const $CopyWithPlaceholder(),
    Object? decision = const $CopyWithPlaceholder(),
    Object? decidedBy = const $CopyWithPlaceholder(),
  }) {
    return ApprovalResolvedEventPayload(
      approvalId: approvalId == const $CopyWithPlaceholder()
          ? _value.approvalId
          // ignore: cast_nullable_to_non_nullable
          : approvalId as String,
      decision: decision == const $CopyWithPlaceholder()
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
  /// Returns a callable class that can be used as follows: `instanceOfApprovalResolvedEventPayload.copyWith(...)` or like so:`instanceOfApprovalResolvedEventPayload.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ApprovalResolvedEventPayloadCWProxy get copyWith =>
      _$ApprovalResolvedEventPayloadCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ApprovalResolvedEventPayload _$ApprovalResolvedEventPayloadFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'ApprovalResolvedEventPayload',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const ['approval_id', 'decision', 'decided_by'],
    );
    final val = ApprovalResolvedEventPayload(
      approvalId: $checkedConvert('approval_id', (v) => v as String),
      decision: $checkedConvert(
        'decision',
        (v) =>
            $enumDecode(_$ApprovalResolvedEventPayloadDecisionEnumEnumMap, v),
      ),
      decidedBy: $checkedConvert('decided_by', (v) => v as String?),
    );
    return val;
  },
  fieldKeyMap: const {'approvalId': 'approval_id', 'decidedBy': 'decided_by'},
);

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
