// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'run_cancelled_event.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$RunCancelledEventCWProxy {
  RunCancelledEvent v(int v);

  RunCancelledEvent runId(String runId);

  RunCancelledEvent seq(int seq);

  RunCancelledEvent ts(DateTime ts);

  RunCancelledEvent botId(String botId);

  RunCancelledEvent type(RunCancelledEventTypeEnum type);

  RunCancelledEvent payload(RunCancelledEventPayload payload);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `RunCancelledEvent(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// RunCancelledEvent(...).copyWith(id: 12, name: "My name")
  /// ```
  RunCancelledEvent call({
    int v,
    String runId,
    int seq,
    DateTime ts,
    String botId,
    RunCancelledEventTypeEnum type,
    RunCancelledEventPayload payload,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfRunCancelledEvent.copyWith(...)` or call `instanceOfRunCancelledEvent.copyWith.fieldName(value)` for a single field.
class _$RunCancelledEventCWProxyImpl implements _$RunCancelledEventCWProxy {
  const _$RunCancelledEventCWProxyImpl(this._value);

  final RunCancelledEvent _value;

  @override
  RunCancelledEvent v(int v) => call(v: v);

  @override
  RunCancelledEvent runId(String runId) => call(runId: runId);

  @override
  RunCancelledEvent seq(int seq) => call(seq: seq);

  @override
  RunCancelledEvent ts(DateTime ts) => call(ts: ts);

  @override
  RunCancelledEvent botId(String botId) => call(botId: botId);

  @override
  RunCancelledEvent type(RunCancelledEventTypeEnum type) => call(type: type);

  @override
  RunCancelledEvent payload(RunCancelledEventPayload payload) =>
      call(payload: payload);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `RunCancelledEvent(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// RunCancelledEvent(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  RunCancelledEvent call({
    Object? v = const $CopyWithPlaceholder(),
    Object? runId = const $CopyWithPlaceholder(),
    Object? seq = const $CopyWithPlaceholder(),
    Object? ts = const $CopyWithPlaceholder(),
    Object? botId = const $CopyWithPlaceholder(),
    Object? type = const $CopyWithPlaceholder(),
    Object? payload = const $CopyWithPlaceholder(),
  }) {
    return RunCancelledEvent(
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
          : type as RunCancelledEventTypeEnum,
      payload: payload == const $CopyWithPlaceholder() || payload == null
          ? _value.payload
          // ignore: cast_nullable_to_non_nullable
          : payload as RunCancelledEventPayload,
    );
  }
}

extension $RunCancelledEventCopyWith on RunCancelledEvent {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfRunCancelledEvent.copyWith(...)` or `instanceOfRunCancelledEvent.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$RunCancelledEventCWProxy get copyWith =>
      _$RunCancelledEventCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RunCancelledEvent _$RunCancelledEventFromJson(Map<String, dynamic> json) =>
    $checkedCreate('RunCancelledEvent', json, ($checkedConvert) {
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
      final val = RunCancelledEvent(
        v: $checkedConvert('v', (v) => (v as num).toInt()),
        runId: $checkedConvert('run_id', (v) => v as String),
        seq: $checkedConvert('seq', (v) => (v as num).toInt()),
        ts: $checkedConvert('ts', (v) => DateTime.parse(v as String)),
        botId: $checkedConvert('bot_id', (v) => v as String),
        type: $checkedConvert(
          'type',
          (v) => $enumDecode(_$RunCancelledEventTypeEnumEnumMap, v),
        ),
        payload: $checkedConvert(
          'payload',
          (v) => RunCancelledEventPayload.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    }, fieldKeyMap: const {'runId': 'run_id', 'botId': 'bot_id'});

Map<String, dynamic> _$RunCancelledEventToJson(RunCancelledEvent instance) =>
    <String, dynamic>{
      'v': instance.v,
      'run_id': instance.runId,
      'seq': instance.seq,
      'ts': instance.ts.toIso8601String(),
      'bot_id': instance.botId,
      'type': _$RunCancelledEventTypeEnumEnumMap[instance.type]!,
      'payload': instance.payload.toJson(),
    };

const _$RunCancelledEventTypeEnumEnumMap = {
  RunCancelledEventTypeEnum.runPeriodCancelled: 'run.cancelled',
};
