// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'approval_requested_event.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ApprovalRequestedEventCWProxy {
  ApprovalRequestedEvent v(int v);

  ApprovalRequestedEvent runId(String runId);

  ApprovalRequestedEvent seq(int seq);

  ApprovalRequestedEvent ts(DateTime ts);

  ApprovalRequestedEvent botId(String botId);

  ApprovalRequestedEvent type(ApprovalRequestedEventTypeEnum type);

  ApprovalRequestedEvent payload(ApprovalRequestedEventPayload payload);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ApprovalRequestedEvent(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ApprovalRequestedEvent(...).copyWith(id: 12, name: "My name")
  /// ````
  ApprovalRequestedEvent call({
    int v,
    String runId,
    int seq,
    DateTime ts,
    String botId,
    ApprovalRequestedEventTypeEnum type,
    ApprovalRequestedEventPayload payload,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfApprovalRequestedEvent.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfApprovalRequestedEvent.copyWith.fieldName(...)`
class _$ApprovalRequestedEventCWProxyImpl
    implements _$ApprovalRequestedEventCWProxy {
  const _$ApprovalRequestedEventCWProxyImpl(this._value);

  final ApprovalRequestedEvent _value;

  @override
  ApprovalRequestedEvent v(int v) => this(v: v);

  @override
  ApprovalRequestedEvent runId(String runId) => this(runId: runId);

  @override
  ApprovalRequestedEvent seq(int seq) => this(seq: seq);

  @override
  ApprovalRequestedEvent ts(DateTime ts) => this(ts: ts);

  @override
  ApprovalRequestedEvent botId(String botId) => this(botId: botId);

  @override
  ApprovalRequestedEvent type(ApprovalRequestedEventTypeEnum type) =>
      this(type: type);

  @override
  ApprovalRequestedEvent payload(ApprovalRequestedEventPayload payload) =>
      this(payload: payload);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ApprovalRequestedEvent(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ApprovalRequestedEvent(...).copyWith(id: 12, name: "My name")
  /// ````
  ApprovalRequestedEvent call({
    Object? v = const $CopyWithPlaceholder(),
    Object? runId = const $CopyWithPlaceholder(),
    Object? seq = const $CopyWithPlaceholder(),
    Object? ts = const $CopyWithPlaceholder(),
    Object? botId = const $CopyWithPlaceholder(),
    Object? type = const $CopyWithPlaceholder(),
    Object? payload = const $CopyWithPlaceholder(),
  }) {
    return ApprovalRequestedEvent(
      v: v == const $CopyWithPlaceholder()
          ? _value.v
          // ignore: cast_nullable_to_non_nullable
          : v as int,
      runId: runId == const $CopyWithPlaceholder()
          ? _value.runId
          // ignore: cast_nullable_to_non_nullable
          : runId as String,
      seq: seq == const $CopyWithPlaceholder()
          ? _value.seq
          // ignore: cast_nullable_to_non_nullable
          : seq as int,
      ts: ts == const $CopyWithPlaceholder()
          ? _value.ts
          // ignore: cast_nullable_to_non_nullable
          : ts as DateTime,
      botId: botId == const $CopyWithPlaceholder()
          ? _value.botId
          // ignore: cast_nullable_to_non_nullable
          : botId as String,
      type: type == const $CopyWithPlaceholder()
          ? _value.type
          // ignore: cast_nullable_to_non_nullable
          : type as ApprovalRequestedEventTypeEnum,
      payload: payload == const $CopyWithPlaceholder()
          ? _value.payload
          // ignore: cast_nullable_to_non_nullable
          : payload as ApprovalRequestedEventPayload,
    );
  }
}

extension $ApprovalRequestedEventCopyWith on ApprovalRequestedEvent {
  /// Returns a callable class that can be used as follows: `instanceOfApprovalRequestedEvent.copyWith(...)` or like so:`instanceOfApprovalRequestedEvent.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ApprovalRequestedEventCWProxy get copyWith =>
      _$ApprovalRequestedEventCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ApprovalRequestedEvent _$ApprovalRequestedEventFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'ApprovalRequestedEvent',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'v',
        'run_id',
        'seq',
        'ts',
        'bot_id',
        'type',
        'payload',
      ],
    );
    final val = ApprovalRequestedEvent(
      v: $checkedConvert('v', (v) => (v as num).toInt()),
      runId: $checkedConvert('run_id', (v) => v as String),
      seq: $checkedConvert('seq', (v) => (v as num).toInt()),
      ts: $checkedConvert('ts', (v) => DateTime.parse(v as String)),
      botId: $checkedConvert('bot_id', (v) => v as String),
      type: $checkedConvert(
        'type',
        (v) => $enumDecode(_$ApprovalRequestedEventTypeEnumEnumMap, v),
      ),
      payload: $checkedConvert(
        'payload',
        (v) =>
            ApprovalRequestedEventPayload.fromJson(v as Map<String, dynamic>),
      ),
    );
    return val;
  },
  fieldKeyMap: const {'runId': 'run_id', 'botId': 'bot_id'},
);

Map<String, dynamic> _$ApprovalRequestedEventToJson(
  ApprovalRequestedEvent instance,
) => <String, dynamic>{
  'v': instance.v,
  'run_id': instance.runId,
  'seq': instance.seq,
  'ts': instance.ts.toIso8601String(),
  'bot_id': instance.botId,
  'type': _$ApprovalRequestedEventTypeEnumEnumMap[instance.type]!,
  'payload': instance.payload.toJson(),
};

const _$ApprovalRequestedEventTypeEnumEnumMap = {
  ApprovalRequestedEventTypeEnum.approvalPeriodRequested: 'approval.requested',
};
