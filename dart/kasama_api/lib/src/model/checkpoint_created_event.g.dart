// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'checkpoint_created_event.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CheckpointCreatedEventCWProxy {
  CheckpointCreatedEvent v(int v);

  CheckpointCreatedEvent runId(String runId);

  CheckpointCreatedEvent seq(int seq);

  CheckpointCreatedEvent ts(DateTime ts);

  CheckpointCreatedEvent botId(String botId);

  CheckpointCreatedEvent type(CheckpointCreatedEventTypeEnum type);

  CheckpointCreatedEvent payload(CheckpointCreatedEventPayload payload);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `CheckpointCreatedEvent(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// CheckpointCreatedEvent(...).copyWith(id: 12, name: "My name")
  /// ````
  CheckpointCreatedEvent call({
    int v,
    String runId,
    int seq,
    DateTime ts,
    String botId,
    CheckpointCreatedEventTypeEnum type,
    CheckpointCreatedEventPayload payload,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfCheckpointCreatedEvent.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfCheckpointCreatedEvent.copyWith.fieldName(...)`
class _$CheckpointCreatedEventCWProxyImpl
    implements _$CheckpointCreatedEventCWProxy {
  const _$CheckpointCreatedEventCWProxyImpl(this._value);

  final CheckpointCreatedEvent _value;

  @override
  CheckpointCreatedEvent v(int v) => this(v: v);

  @override
  CheckpointCreatedEvent runId(String runId) => this(runId: runId);

  @override
  CheckpointCreatedEvent seq(int seq) => this(seq: seq);

  @override
  CheckpointCreatedEvent ts(DateTime ts) => this(ts: ts);

  @override
  CheckpointCreatedEvent botId(String botId) => this(botId: botId);

  @override
  CheckpointCreatedEvent type(CheckpointCreatedEventTypeEnum type) =>
      this(type: type);

  @override
  CheckpointCreatedEvent payload(CheckpointCreatedEventPayload payload) =>
      this(payload: payload);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `CheckpointCreatedEvent(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// CheckpointCreatedEvent(...).copyWith(id: 12, name: "My name")
  /// ````
  CheckpointCreatedEvent call({
    Object? v = const $CopyWithPlaceholder(),
    Object? runId = const $CopyWithPlaceholder(),
    Object? seq = const $CopyWithPlaceholder(),
    Object? ts = const $CopyWithPlaceholder(),
    Object? botId = const $CopyWithPlaceholder(),
    Object? type = const $CopyWithPlaceholder(),
    Object? payload = const $CopyWithPlaceholder(),
  }) {
    return CheckpointCreatedEvent(
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
          : type as CheckpointCreatedEventTypeEnum,
      payload: payload == const $CopyWithPlaceholder()
          ? _value.payload
          // ignore: cast_nullable_to_non_nullable
          : payload as CheckpointCreatedEventPayload,
    );
  }
}

extension $CheckpointCreatedEventCopyWith on CheckpointCreatedEvent {
  /// Returns a callable class that can be used as follows: `instanceOfCheckpointCreatedEvent.copyWith(...)` or like so:`instanceOfCheckpointCreatedEvent.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CheckpointCreatedEventCWProxy get copyWith =>
      _$CheckpointCreatedEventCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CheckpointCreatedEvent _$CheckpointCreatedEventFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'CheckpointCreatedEvent',
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
    final val = CheckpointCreatedEvent(
      v: $checkedConvert('v', (v) => (v as num).toInt()),
      runId: $checkedConvert('run_id', (v) => v as String),
      seq: $checkedConvert('seq', (v) => (v as num).toInt()),
      ts: $checkedConvert('ts', (v) => DateTime.parse(v as String)),
      botId: $checkedConvert('bot_id', (v) => v as String),
      type: $checkedConvert(
        'type',
        (v) => $enumDecode(_$CheckpointCreatedEventTypeEnumEnumMap, v),
      ),
      payload: $checkedConvert(
        'payload',
        (v) =>
            CheckpointCreatedEventPayload.fromJson(v as Map<String, dynamic>),
      ),
    );
    return val;
  },
  fieldKeyMap: const {'runId': 'run_id', 'botId': 'bot_id'},
);

Map<String, dynamic> _$CheckpointCreatedEventToJson(
  CheckpointCreatedEvent instance,
) => <String, dynamic>{
  'v': instance.v,
  'run_id': instance.runId,
  'seq': instance.seq,
  'ts': instance.ts.toIso8601String(),
  'bot_id': instance.botId,
  'type': _$CheckpointCreatedEventTypeEnumEnumMap[instance.type]!,
  'payload': instance.payload.toJson(),
};

const _$CheckpointCreatedEventTypeEnumEnumMap = {
  CheckpointCreatedEventTypeEnum.checkpointPeriodCreated: 'checkpoint.created',
};
