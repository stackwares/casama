// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'run_started_event.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$RunStartedEventCWProxy {
  RunStartedEvent v(int v);

  RunStartedEvent runId(String runId);

  RunStartedEvent seq(int seq);

  RunStartedEvent ts(DateTime ts);

  RunStartedEvent botId(String botId);

  RunStartedEvent type(RunStartedEventTypeEnum type);

  RunStartedEvent payload(RunStartedEventPayload payload);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `RunStartedEvent(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// RunStartedEvent(...).copyWith(id: 12, name: "My name")
  /// ````
  RunStartedEvent call({
    int v,
    String runId,
    int seq,
    DateTime ts,
    String botId,
    RunStartedEventTypeEnum type,
    RunStartedEventPayload payload,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfRunStartedEvent.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfRunStartedEvent.copyWith.fieldName(...)`
class _$RunStartedEventCWProxyImpl implements _$RunStartedEventCWProxy {
  const _$RunStartedEventCWProxyImpl(this._value);

  final RunStartedEvent _value;

  @override
  RunStartedEvent v(int v) => this(v: v);

  @override
  RunStartedEvent runId(String runId) => this(runId: runId);

  @override
  RunStartedEvent seq(int seq) => this(seq: seq);

  @override
  RunStartedEvent ts(DateTime ts) => this(ts: ts);

  @override
  RunStartedEvent botId(String botId) => this(botId: botId);

  @override
  RunStartedEvent type(RunStartedEventTypeEnum type) => this(type: type);

  @override
  RunStartedEvent payload(RunStartedEventPayload payload) =>
      this(payload: payload);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `RunStartedEvent(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// RunStartedEvent(...).copyWith(id: 12, name: "My name")
  /// ````
  RunStartedEvent call({
    Object? v = const $CopyWithPlaceholder(),
    Object? runId = const $CopyWithPlaceholder(),
    Object? seq = const $CopyWithPlaceholder(),
    Object? ts = const $CopyWithPlaceholder(),
    Object? botId = const $CopyWithPlaceholder(),
    Object? type = const $CopyWithPlaceholder(),
    Object? payload = const $CopyWithPlaceholder(),
  }) {
    return RunStartedEvent(
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
          : type as RunStartedEventTypeEnum,
      payload: payload == const $CopyWithPlaceholder()
          ? _value.payload
          // ignore: cast_nullable_to_non_nullable
          : payload as RunStartedEventPayload,
    );
  }
}

extension $RunStartedEventCopyWith on RunStartedEvent {
  /// Returns a callable class that can be used as follows: `instanceOfRunStartedEvent.copyWith(...)` or like so:`instanceOfRunStartedEvent.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$RunStartedEventCWProxy get copyWith => _$RunStartedEventCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RunStartedEvent _$RunStartedEventFromJson(Map<String, dynamic> json) =>
    $checkedCreate('RunStartedEvent', json, ($checkedConvert) {
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
      final val = RunStartedEvent(
        v: $checkedConvert('v', (v) => (v as num).toInt()),
        runId: $checkedConvert('run_id', (v) => v as String),
        seq: $checkedConvert('seq', (v) => (v as num).toInt()),
        ts: $checkedConvert('ts', (v) => DateTime.parse(v as String)),
        botId: $checkedConvert('bot_id', (v) => v as String),
        type: $checkedConvert(
          'type',
          (v) => $enumDecode(_$RunStartedEventTypeEnumEnumMap, v),
        ),
        payload: $checkedConvert(
          'payload',
          (v) => RunStartedEventPayload.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    }, fieldKeyMap: const {'runId': 'run_id', 'botId': 'bot_id'});

Map<String, dynamic> _$RunStartedEventToJson(RunStartedEvent instance) =>
    <String, dynamic>{
      'v': instance.v,
      'run_id': instance.runId,
      'seq': instance.seq,
      'ts': instance.ts.toIso8601String(),
      'bot_id': instance.botId,
      'type': _$RunStartedEventTypeEnumEnumMap[instance.type]!,
      'payload': instance.payload.toJson(),
    };

const _$RunStartedEventTypeEnumEnumMap = {
  RunStartedEventTypeEnum.runPeriodStarted: 'run.started',
};
