// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'memory_written_event.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$MemoryWrittenEventCWProxy {
  MemoryWrittenEvent v(int v);

  MemoryWrittenEvent runId(String runId);

  MemoryWrittenEvent seq(int seq);

  MemoryWrittenEvent ts(DateTime ts);

  MemoryWrittenEvent botId(String botId);

  MemoryWrittenEvent type(MemoryWrittenEventTypeEnum type);

  MemoryWrittenEvent payload(MemoryWrittenEventPayload payload);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `MemoryWrittenEvent(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// MemoryWrittenEvent(...).copyWith(id: 12, name: "My name")
  /// ```
  MemoryWrittenEvent call({
    int v,
    String runId,
    int seq,
    DateTime ts,
    String botId,
    MemoryWrittenEventTypeEnum type,
    MemoryWrittenEventPayload payload,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfMemoryWrittenEvent.copyWith(...)` or call `instanceOfMemoryWrittenEvent.copyWith.fieldName(value)` for a single field.
class _$MemoryWrittenEventCWProxyImpl implements _$MemoryWrittenEventCWProxy {
  const _$MemoryWrittenEventCWProxyImpl(this._value);

  final MemoryWrittenEvent _value;

  @override
  MemoryWrittenEvent v(int v) => call(v: v);

  @override
  MemoryWrittenEvent runId(String runId) => call(runId: runId);

  @override
  MemoryWrittenEvent seq(int seq) => call(seq: seq);

  @override
  MemoryWrittenEvent ts(DateTime ts) => call(ts: ts);

  @override
  MemoryWrittenEvent botId(String botId) => call(botId: botId);

  @override
  MemoryWrittenEvent type(MemoryWrittenEventTypeEnum type) => call(type: type);

  @override
  MemoryWrittenEvent payload(MemoryWrittenEventPayload payload) =>
      call(payload: payload);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `MemoryWrittenEvent(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// MemoryWrittenEvent(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  MemoryWrittenEvent call({
    Object? v = const $CopyWithPlaceholder(),
    Object? runId = const $CopyWithPlaceholder(),
    Object? seq = const $CopyWithPlaceholder(),
    Object? ts = const $CopyWithPlaceholder(),
    Object? botId = const $CopyWithPlaceholder(),
    Object? type = const $CopyWithPlaceholder(),
    Object? payload = const $CopyWithPlaceholder(),
  }) {
    return MemoryWrittenEvent(
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
          : type as MemoryWrittenEventTypeEnum,
      payload: payload == const $CopyWithPlaceholder() || payload == null
          ? _value.payload
          // ignore: cast_nullable_to_non_nullable
          : payload as MemoryWrittenEventPayload,
    );
  }
}

extension $MemoryWrittenEventCopyWith on MemoryWrittenEvent {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfMemoryWrittenEvent.copyWith(...)` or `instanceOfMemoryWrittenEvent.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$MemoryWrittenEventCWProxy get copyWith =>
      _$MemoryWrittenEventCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MemoryWrittenEvent _$MemoryWrittenEventFromJson(Map<String, dynamic> json) =>
    $checkedCreate('MemoryWrittenEvent', json, ($checkedConvert) {
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
      final val = MemoryWrittenEvent(
        v: $checkedConvert('v', (v) => (v as num).toInt()),
        runId: $checkedConvert('run_id', (v) => v as String),
        seq: $checkedConvert('seq', (v) => (v as num).toInt()),
        ts: $checkedConvert('ts', (v) => DateTime.parse(v as String)),
        botId: $checkedConvert('bot_id', (v) => v as String),
        type: $checkedConvert(
          'type',
          (v) => $enumDecode(_$MemoryWrittenEventTypeEnumEnumMap, v),
        ),
        payload: $checkedConvert(
          'payload',
          (v) => MemoryWrittenEventPayload.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    }, fieldKeyMap: const {'runId': 'run_id', 'botId': 'bot_id'});

Map<String, dynamic> _$MemoryWrittenEventToJson(MemoryWrittenEvent instance) =>
    <String, dynamic>{
      'v': instance.v,
      'run_id': instance.runId,
      'seq': instance.seq,
      'ts': instance.ts.toIso8601String(),
      'bot_id': instance.botId,
      'type': _$MemoryWrittenEventTypeEnumEnumMap[instance.type]!,
      'payload': instance.payload.toJson(),
    };

const _$MemoryWrittenEventTypeEnumEnumMap = {
  MemoryWrittenEventTypeEnum.memoryPeriodWritten: 'memory.written',
};
