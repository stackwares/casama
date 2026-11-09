// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'approval_requested_event_payload.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ApprovalRequestedEventPayloadCWProxy {
  ApprovalRequestedEventPayload approvalId(String approvalId);

  ApprovalRequestedEventPayload tool(String tool);

  ApprovalRequestedEventPayload argsRedacted(Map<String, Object?> argsRedacted);

  ApprovalRequestedEventPayload risk(
    ApprovalRequestedEventPayloadRiskEnum risk,
  );

  ApprovalRequestedEventPayload expiresAt(DateTime expiresAt);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ApprovalRequestedEventPayload(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ApprovalRequestedEventPayload(...).copyWith(id: 12, name: "My name")
  /// ````
  ApprovalRequestedEventPayload call({
    String approvalId,
    String tool,
    Map<String, Object?> argsRedacted,
    ApprovalRequestedEventPayloadRiskEnum risk,
    DateTime expiresAt,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfApprovalRequestedEventPayload.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfApprovalRequestedEventPayload.copyWith.fieldName(...)`
class _$ApprovalRequestedEventPayloadCWProxyImpl
    implements _$ApprovalRequestedEventPayloadCWProxy {
  const _$ApprovalRequestedEventPayloadCWProxyImpl(this._value);

  final ApprovalRequestedEventPayload _value;

  @override
  ApprovalRequestedEventPayload approvalId(String approvalId) =>
      this(approvalId: approvalId);

  @override
  ApprovalRequestedEventPayload tool(String tool) => this(tool: tool);

  @override
  ApprovalRequestedEventPayload argsRedacted(
    Map<String, Object?> argsRedacted,
  ) => this(argsRedacted: argsRedacted);

  @override
  ApprovalRequestedEventPayload risk(
    ApprovalRequestedEventPayloadRiskEnum risk,
  ) => this(risk: risk);

  @override
  ApprovalRequestedEventPayload expiresAt(DateTime expiresAt) =>
      this(expiresAt: expiresAt);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ApprovalRequestedEventPayload(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ApprovalRequestedEventPayload(...).copyWith(id: 12, name: "My name")
  /// ````
  ApprovalRequestedEventPayload call({
    Object? approvalId = const $CopyWithPlaceholder(),
    Object? tool = const $CopyWithPlaceholder(),
    Object? argsRedacted = const $CopyWithPlaceholder(),
    Object? risk = const $CopyWithPlaceholder(),
    Object? expiresAt = const $CopyWithPlaceholder(),
  }) {
    return ApprovalRequestedEventPayload(
      approvalId: approvalId == const $CopyWithPlaceholder()
          ? _value.approvalId
          // ignore: cast_nullable_to_non_nullable
          : approvalId as String,
      tool: tool == const $CopyWithPlaceholder()
          ? _value.tool
          // ignore: cast_nullable_to_non_nullable
          : tool as String,
      argsRedacted: argsRedacted == const $CopyWithPlaceholder()
          ? _value.argsRedacted
          // ignore: cast_nullable_to_non_nullable
          : argsRedacted as Map<String, Object?>,
      risk: risk == const $CopyWithPlaceholder()
          ? _value.risk
          // ignore: cast_nullable_to_non_nullable
          : risk as ApprovalRequestedEventPayloadRiskEnum,
      expiresAt: expiresAt == const $CopyWithPlaceholder()
          ? _value.expiresAt
          // ignore: cast_nullable_to_non_nullable
          : expiresAt as DateTime,
    );
  }
}

extension $ApprovalRequestedEventPayloadCopyWith
    on ApprovalRequestedEventPayload {
  /// Returns a callable class that can be used as follows: `instanceOfApprovalRequestedEventPayload.copyWith(...)` or like so:`instanceOfApprovalRequestedEventPayload.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ApprovalRequestedEventPayloadCWProxy get copyWith =>
      _$ApprovalRequestedEventPayloadCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ApprovalRequestedEventPayload _$ApprovalRequestedEventPayloadFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'ApprovalRequestedEventPayload',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'approval_id',
        'tool',
        'args_redacted',
        'risk',
        'expires_at',
      ],
    );
    final val = ApprovalRequestedEventPayload(
      approvalId: $checkedConvert('approval_id', (v) => v as String),
      tool: $checkedConvert('tool', (v) => v as String),
      argsRedacted: $checkedConvert(
        'args_redacted',
        (v) => v as Map<String, dynamic>,
      ),
      risk: $checkedConvert(
        'risk',
        (v) => $enumDecode(_$ApprovalRequestedEventPayloadRiskEnumEnumMap, v),
      ),
      expiresAt: $checkedConvert(
        'expires_at',
        (v) => DateTime.parse(v as String),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'approvalId': 'approval_id',
    'argsRedacted': 'args_redacted',
    'expiresAt': 'expires_at',
  },
);

Map<String, dynamic> _$ApprovalRequestedEventPayloadToJson(
  ApprovalRequestedEventPayload instance,
) => <String, dynamic>{
  'approval_id': instance.approvalId,
  'tool': instance.tool,
  'args_redacted': instance.argsRedacted,
  'risk': _$ApprovalRequestedEventPayloadRiskEnumEnumMap[instance.risk]!,
  'expires_at': instance.expiresAt.toIso8601String(),
};

const _$ApprovalRequestedEventPayloadRiskEnumEnumMap = {
  ApprovalRequestedEventPayloadRiskEnum.low: 'low',
  ApprovalRequestedEventPayloadRiskEnum.medium: 'medium',
  ApprovalRequestedEventPayloadRiskEnum.high: 'high',
};
