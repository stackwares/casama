// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'computer_state_event.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ComputerStateEventCWProxy {
  ComputerStateEvent v(int v);

  ComputerStateEvent runId(String runId);

  ComputerStateEvent seq(int seq);

  ComputerStateEvent ts(DateTime ts);

  ComputerStateEvent botId(String botId);

  ComputerStateEvent type(ComputerStateEventTypeEnum type);

  ComputerStateEvent payload(ComputerStateEventPayload payload);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ComputerStateEvent(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ComputerStateEvent(...).copyWith(id: 12, name: "My name")
  /// ```
  ComputerStateEvent call({
    int v,
    String runId,
    int seq,
    DateTime ts,
    String botId,
    ComputerStateEventTypeEnum type,
    ComputerStateEventPayload payload,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfComputerStateEvent.copyWith(...)` or call `instanceOfComputerStateEvent.copyWith.fieldName(value)` for a single field.
class _$ComputerStateEventCWProxyImpl implements _$ComputerStateEventCWProxy {
  const _$ComputerStateEventCWProxyImpl(this._value);

  final ComputerStateEvent _value;

  @override
  ComputerStateEvent v(int v) => call(v: v);

  @override
  ComputerStateEvent runId(String runId) => call(runId: runId);

  @override
  ComputerStateEvent seq(int seq) => call(seq: seq);

  @override
  ComputerStateEvent ts(DateTime ts) => call(ts: ts);

  @override
  ComputerStateEvent botId(String botId) => call(botId: botId);

  @override
  ComputerStateEvent type(ComputerStateEventTypeEnum type) => call(type: type);

  @override
  ComputerStateEvent payload(ComputerStateEventPayload payload) =>
      call(payload: payload);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ComputerStateEvent(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ComputerStateEvent(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ComputerStateEvent call({
    Object? v = const $CopyWithPlaceholder(),
    Object? runId = const $CopyWithPlaceholder(),
    Object? seq = const $CopyWithPlaceholder(),
    Object? ts = const $CopyWithPlaceholder(),
    Object? botId = const $CopyWithPlaceholder(),
    Object? type = const $CopyWithPlaceholder(),
    Object? payload = const $CopyWithPlaceholder(),
  }) {
    return ComputerStateEvent(
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
          : type as ComputerStateEventTypeEnum,
      payload: payload == const $CopyWithPlaceholder() || payload == null
          ? _value.payload
          // ignore: cast_nullable_to_non_nullable
          : payload as ComputerStateEventPayload,
    );
  }
}

extension $ComputerStateEventCopyWith on ComputerStateEvent {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfComputerStateEvent.copyWith(...)` or `instanceOfComputerStateEvent.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ComputerStateEventCWProxy get copyWith =>
      _$ComputerStateEventCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ComputerStateEvent _$ComputerStateEventFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ComputerStateEvent', json, ($checkedConvert) {
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
      final val = ComputerStateEvent(
        v: $checkedConvert('v', (v) => (v as num).toInt()),
        runId: $checkedConvert('run_id', (v) => v as String),
        seq: $checkedConvert('seq', (v) => (v as num).toInt()),
        ts: $checkedConvert('ts', (v) => DateTime.parse(v as String)),
        botId: $checkedConvert('bot_id', (v) => v as String),
        type: $checkedConvert(
          'type',
          (v) => $enumDecode(_$ComputerStateEventTypeEnumEnumMap, v),
        ),
        payload: $checkedConvert(
          'payload',
          (v) => ComputerStateEventPayload.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    }, fieldKeyMap: const {'runId': 'run_id', 'botId': 'bot_id'});

Map<String, dynamic> _$ComputerStateEventToJson(ComputerStateEvent instance) =>
    <String, dynamic>{
      'v': instance.v,
      'run_id': instance.runId,
      'seq': instance.seq,
      'ts': instance.ts.toIso8601String(),
      'bot_id': instance.botId,
      'type': _$ComputerStateEventTypeEnumEnumMap[instance.type]!,
      'payload': instance.payload.toJson(),
    };

const _$ComputerStateEventTypeEnumEnumMap = {
  ComputerStateEventTypeEnum.computerPeriodState: 'computer.state',
};
