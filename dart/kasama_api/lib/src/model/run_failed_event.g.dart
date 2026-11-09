// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'run_failed_event.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$RunFailedEventCWProxy {
  RunFailedEvent v(int v);

  RunFailedEvent runId(String runId);

  RunFailedEvent seq(int seq);

  RunFailedEvent ts(DateTime ts);

  RunFailedEvent botId(String botId);

  RunFailedEvent type(RunFailedEventTypeEnum type);

  RunFailedEvent payload(RunFailedEventPayload payload);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `RunFailedEvent(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// RunFailedEvent(...).copyWith(id: 12, name: "My name")
  /// ````
  RunFailedEvent call({
    int v,
    String runId,
    int seq,
    DateTime ts,
    String botId,
    RunFailedEventTypeEnum type,
    RunFailedEventPayload payload,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfRunFailedEvent.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfRunFailedEvent.copyWith.fieldName(...)`
class _$RunFailedEventCWProxyImpl implements _$RunFailedEventCWProxy {
  const _$RunFailedEventCWProxyImpl(this._value);

  final RunFailedEvent _value;

  @override
  RunFailedEvent v(int v) => this(v: v);

  @override
  RunFailedEvent runId(String runId) => this(runId: runId);

  @override
  RunFailedEvent seq(int seq) => this(seq: seq);

  @override
  RunFailedEvent ts(DateTime ts) => this(ts: ts);

  @override
  RunFailedEvent botId(String botId) => this(botId: botId);

  @override
  RunFailedEvent type(RunFailedEventTypeEnum type) => this(type: type);

  @override
  RunFailedEvent payload(RunFailedEventPayload payload) =>
      this(payload: payload);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `RunFailedEvent(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// RunFailedEvent(...).copyWith(id: 12, name: "My name")
  /// ````
  RunFailedEvent call({
    Object? v = const $CopyWithPlaceholder(),
    Object? runId = const $CopyWithPlaceholder(),
    Object? seq = const $CopyWithPlaceholder(),
    Object? ts = const $CopyWithPlaceholder(),
    Object? botId = const $CopyWithPlaceholder(),
    Object? type = const $CopyWithPlaceholder(),
    Object? payload = const $CopyWithPlaceholder(),
  }) {
    return RunFailedEvent(
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
          : type as RunFailedEventTypeEnum,
      payload: payload == const $CopyWithPlaceholder()
          ? _value.payload
          // ignore: cast_nullable_to_non_nullable
          : payload as RunFailedEventPayload,
    );
  }
}

extension $RunFailedEventCopyWith on RunFailedEvent {
  /// Returns a callable class that can be used as follows: `instanceOfRunFailedEvent.copyWith(...)` or like so:`instanceOfRunFailedEvent.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$RunFailedEventCWProxy get copyWith => _$RunFailedEventCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RunFailedEvent _$RunFailedEventFromJson(Map<String, dynamic> json) =>
    $checkedCreate('RunFailedEvent', json, ($checkedConvert) {
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
      final val = RunFailedEvent(
        v: $checkedConvert('v', (v) => (v as num).toInt()),
        runId: $checkedConvert('run_id', (v) => v as String),
        seq: $checkedConvert('seq', (v) => (v as num).toInt()),
        ts: $checkedConvert('ts', (v) => DateTime.parse(v as String)),
        botId: $checkedConvert('bot_id', (v) => v as String),
        type: $checkedConvert(
          'type',
          (v) => $enumDecode(_$RunFailedEventTypeEnumEnumMap, v),
        ),
        payload: $checkedConvert(
          'payload',
          (v) => RunFailedEventPayload.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    }, fieldKeyMap: const {'runId': 'run_id', 'botId': 'bot_id'});

Map<String, dynamic> _$RunFailedEventToJson(RunFailedEvent instance) =>
    <String, dynamic>{
      'v': instance.v,
      'run_id': instance.runId,
      'seq': instance.seq,
      'ts': instance.ts.toIso8601String(),
      'bot_id': instance.botId,
      'type': _$RunFailedEventTypeEnumEnumMap[instance.type]!,
      'payload': instance.payload.toJson(),
    };

const _$RunFailedEventTypeEnumEnumMap = {
  RunFailedEventTypeEnum.runPeriodFailed: 'run.failed',
};
