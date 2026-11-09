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

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `MemoryWrittenEvent(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// MemoryWrittenEvent(...).copyWith(id: 12, name: "My name")
  /// ````
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

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfMemoryWrittenEvent.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfMemoryWrittenEvent.copyWith.fieldName(...)`
class _$MemoryWrittenEventCWProxyImpl implements _$MemoryWrittenEventCWProxy {
  const _$MemoryWrittenEventCWProxyImpl(this._value);

  final MemoryWrittenEvent _value;

  @override
  MemoryWrittenEvent v(int v) => this(v: v);

  @override
  MemoryWrittenEvent runId(String runId) => this(runId: runId);

  @override
  MemoryWrittenEvent seq(int seq) => this(seq: seq);

  @override
  MemoryWrittenEvent ts(DateTime ts) => this(ts: ts);

  @override
  MemoryWrittenEvent botId(String botId) => this(botId: botId);

  @override
  MemoryWrittenEvent type(MemoryWrittenEventTypeEnum type) => this(type: type);

  @override
  MemoryWrittenEvent payload(MemoryWrittenEventPayload payload) =>
      this(payload: payload);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `MemoryWrittenEvent(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// MemoryWrittenEvent(...).copyWith(id: 12, name: "My name")
  /// ````
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
          : type as MemoryWrittenEventTypeEnum,
      payload: payload == const $CopyWithPlaceholder()
          ? _value.payload
          // ignore: cast_nullable_to_non_nullable
          : payload as MemoryWrittenEventPayload,
    );
  }
}

extension $MemoryWrittenEventCopyWith on MemoryWrittenEvent {
  /// Returns a callable class that can be used as follows: `instanceOfMemoryWrittenEvent.copyWith(...)` or like so:`instanceOfMemoryWrittenEvent.copyWith.fieldName(...)`.
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
