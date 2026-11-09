// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'run_completed_event.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$RunCompletedEventCWProxy {
  RunCompletedEvent v(int v);

  RunCompletedEvent runId(String runId);

  RunCompletedEvent seq(int seq);

  RunCompletedEvent ts(DateTime ts);

  RunCompletedEvent botId(String botId);

  RunCompletedEvent type(RunCompletedEventTypeEnum type);

  RunCompletedEvent payload(RunCompletedEventPayload payload);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `RunCompletedEvent(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// RunCompletedEvent(...).copyWith(id: 12, name: "My name")
  /// ````
  RunCompletedEvent call({
    int v,
    String runId,
    int seq,
    DateTime ts,
    String botId,
    RunCompletedEventTypeEnum type,
    RunCompletedEventPayload payload,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfRunCompletedEvent.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfRunCompletedEvent.copyWith.fieldName(...)`
class _$RunCompletedEventCWProxyImpl implements _$RunCompletedEventCWProxy {
  const _$RunCompletedEventCWProxyImpl(this._value);

  final RunCompletedEvent _value;

  @override
  RunCompletedEvent v(int v) => this(v: v);

  @override
  RunCompletedEvent runId(String runId) => this(runId: runId);

  @override
  RunCompletedEvent seq(int seq) => this(seq: seq);

  @override
  RunCompletedEvent ts(DateTime ts) => this(ts: ts);

  @override
  RunCompletedEvent botId(String botId) => this(botId: botId);

  @override
  RunCompletedEvent type(RunCompletedEventTypeEnum type) => this(type: type);

  @override
  RunCompletedEvent payload(RunCompletedEventPayload payload) =>
      this(payload: payload);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `RunCompletedEvent(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// RunCompletedEvent(...).copyWith(id: 12, name: "My name")
  /// ````
  RunCompletedEvent call({
    Object? v = const $CopyWithPlaceholder(),
    Object? runId = const $CopyWithPlaceholder(),
    Object? seq = const $CopyWithPlaceholder(),
    Object? ts = const $CopyWithPlaceholder(),
    Object? botId = const $CopyWithPlaceholder(),
    Object? type = const $CopyWithPlaceholder(),
    Object? payload = const $CopyWithPlaceholder(),
  }) {
    return RunCompletedEvent(
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
          : type as RunCompletedEventTypeEnum,
      payload: payload == const $CopyWithPlaceholder()
          ? _value.payload
          // ignore: cast_nullable_to_non_nullable
          : payload as RunCompletedEventPayload,
    );
  }
}

extension $RunCompletedEventCopyWith on RunCompletedEvent {
  /// Returns a callable class that can be used as follows: `instanceOfRunCompletedEvent.copyWith(...)` or like so:`instanceOfRunCompletedEvent.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$RunCompletedEventCWProxy get copyWith =>
      _$RunCompletedEventCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RunCompletedEvent _$RunCompletedEventFromJson(Map<String, dynamic> json) =>
    $checkedCreate('RunCompletedEvent', json, ($checkedConvert) {
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
      final val = RunCompletedEvent(
        v: $checkedConvert('v', (v) => (v as num).toInt()),
        runId: $checkedConvert('run_id', (v) => v as String),
        seq: $checkedConvert('seq', (v) => (v as num).toInt()),
        ts: $checkedConvert('ts', (v) => DateTime.parse(v as String)),
        botId: $checkedConvert('bot_id', (v) => v as String),
        type: $checkedConvert(
          'type',
          (v) => $enumDecode(_$RunCompletedEventTypeEnumEnumMap, v),
        ),
        payload: $checkedConvert(
          'payload',
          (v) => RunCompletedEventPayload.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    }, fieldKeyMap: const {'runId': 'run_id', 'botId': 'bot_id'});

Map<String, dynamic> _$RunCompletedEventToJson(RunCompletedEvent instance) =>
    <String, dynamic>{
      'v': instance.v,
      'run_id': instance.runId,
      'seq': instance.seq,
      'ts': instance.ts.toIso8601String(),
      'bot_id': instance.botId,
      'type': _$RunCompletedEventTypeEnumEnumMap[instance.type]!,
      'payload': instance.payload.toJson(),
    };

const _$RunCompletedEventTypeEnumEnumMap = {
  RunCompletedEventTypeEnum.runPeriodCompleted: 'run.completed',
};
