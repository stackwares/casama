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

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `RunFailedEvent(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// RunFailedEvent(...).copyWith(id: 12, name: "My name")
  /// ```
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

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfRunFailedEvent.copyWith(...)` or call `instanceOfRunFailedEvent.copyWith.fieldName(value)` for a single field.
class _$RunFailedEventCWProxyImpl implements _$RunFailedEventCWProxy {
  const _$RunFailedEventCWProxyImpl(this._value);

  final RunFailedEvent _value;

  @override
  RunFailedEvent v(int v) => call(v: v);

  @override
  RunFailedEvent runId(String runId) => call(runId: runId);

  @override
  RunFailedEvent seq(int seq) => call(seq: seq);

  @override
  RunFailedEvent ts(DateTime ts) => call(ts: ts);

  @override
  RunFailedEvent botId(String botId) => call(botId: botId);

  @override
  RunFailedEvent type(RunFailedEventTypeEnum type) => call(type: type);

  @override
  RunFailedEvent payload(RunFailedEventPayload payload) =>
      call(payload: payload);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `RunFailedEvent(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// RunFailedEvent(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
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
          : type as RunFailedEventTypeEnum,
      payload: payload == const $CopyWithPlaceholder() || payload == null
          ? _value.payload
          // ignore: cast_nullable_to_non_nullable
          : payload as RunFailedEventPayload,
    );
  }
}

extension $RunFailedEventCopyWith on RunFailedEvent {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfRunFailedEvent.copyWith(...)` or `instanceOfRunFailedEvent.copyWith.fieldName(...)`.
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
