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

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CheckpointCreatedEvent(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CheckpointCreatedEvent(...).copyWith(id: 12, name: "My name")
  /// ```
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

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfCheckpointCreatedEvent.copyWith(...)` or call `instanceOfCheckpointCreatedEvent.copyWith.fieldName(value)` for a single field.
class _$CheckpointCreatedEventCWProxyImpl
    implements _$CheckpointCreatedEventCWProxy {
  const _$CheckpointCreatedEventCWProxyImpl(this._value);

  final CheckpointCreatedEvent _value;

  @override
  CheckpointCreatedEvent v(int v) => call(v: v);

  @override
  CheckpointCreatedEvent runId(String runId) => call(runId: runId);

  @override
  CheckpointCreatedEvent seq(int seq) => call(seq: seq);

  @override
  CheckpointCreatedEvent ts(DateTime ts) => call(ts: ts);

  @override
  CheckpointCreatedEvent botId(String botId) => call(botId: botId);

  @override
  CheckpointCreatedEvent type(CheckpointCreatedEventTypeEnum type) =>
      call(type: type);

  @override
  CheckpointCreatedEvent payload(CheckpointCreatedEventPayload payload) =>
      call(payload: payload);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CheckpointCreatedEvent(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CheckpointCreatedEvent(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
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
      v: v == const $CopyWithPlaceholder() || v == null
          ? _value.v
          // ignore: cast_nullable_to_non_nullable
          : v as int,
      runId: runId == const $CopyWithPlaceholder() || runId == null
          ? _value.runId
          // ignore: cast_nullable_to_non_nullable
          : runId as String,
      seq: seq == const $CopyWithPlaceholder() || seq == null
          ? _value.seq
          // ignore: cast_nullable_to_non_nullable
          : seq as int,
      ts: ts == const $CopyWithPlaceholder() || ts == null
          ? _value.ts
          // ignore: cast_nullable_to_non_nullable
          : ts as DateTime,
      botId: botId == const $CopyWithPlaceholder() || botId == null
          ? _value.botId
          // ignore: cast_nullable_to_non_nullable
          : botId as String,
      type: type == const $CopyWithPlaceholder() || type == null
          ? _value.type
          // ignore: cast_nullable_to_non_nullable
          : type as CheckpointCreatedEventTypeEnum,
      payload: payload == const $CopyWithPlaceholder() || payload == null
          ? _value.payload
          // ignore: cast_nullable_to_non_nullable
          : payload as CheckpointCreatedEventPayload,
    );
  }
}

extension $CheckpointCreatedEventCopyWith on CheckpointCreatedEvent {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfCheckpointCreatedEvent.copyWith(...)` or `instanceOfCheckpointCreatedEvent.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CheckpointCreatedEventCWProxy get copyWith =>
      _$CheckpointCreatedEventCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CheckpointCreatedEvent _$CheckpointCreatedEventFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('CheckpointCreatedEvent', json, ($checkedConvert) {
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
      (v) => CheckpointCreatedEventPayload.fromJson(v as Map<String, dynamic>),
    ),
  );
  return val;
}, fieldKeyMap: const {'runId': 'run_id', 'botId': 'bot_id'});

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
