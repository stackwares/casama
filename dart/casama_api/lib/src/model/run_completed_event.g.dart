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

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `RunCompletedEvent(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// RunCompletedEvent(...).copyWith(id: 12, name: "My name")
  /// ```
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

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfRunCompletedEvent.copyWith(...)` or call `instanceOfRunCompletedEvent.copyWith.fieldName(value)` for a single field.
class _$RunCompletedEventCWProxyImpl implements _$RunCompletedEventCWProxy {
  const _$RunCompletedEventCWProxyImpl(this._value);

  final RunCompletedEvent _value;

  @override
  RunCompletedEvent v(int v) => call(v: v);

  @override
  RunCompletedEvent runId(String runId) => call(runId: runId);

  @override
  RunCompletedEvent seq(int seq) => call(seq: seq);

  @override
  RunCompletedEvent ts(DateTime ts) => call(ts: ts);

  @override
  RunCompletedEvent botId(String botId) => call(botId: botId);

  @override
  RunCompletedEvent type(RunCompletedEventTypeEnum type) => call(type: type);

  @override
  RunCompletedEvent payload(RunCompletedEventPayload payload) =>
      call(payload: payload);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `RunCompletedEvent(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// RunCompletedEvent(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
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
          : type as RunCompletedEventTypeEnum,
      payload: payload == const $CopyWithPlaceholder() || payload == null
          ? _value.payload
          // ignore: cast_nullable_to_non_nullable
          : payload as RunCompletedEventPayload,
    );
  }
}

extension $RunCompletedEventCopyWith on RunCompletedEvent {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfRunCompletedEvent.copyWith(...)` or `instanceOfRunCompletedEvent.copyWith.fieldName(...)`.
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
