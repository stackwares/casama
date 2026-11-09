// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tool_completed_event.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ToolCompletedEventCWProxy {
  ToolCompletedEvent v(int v);

  ToolCompletedEvent runId(String runId);

  ToolCompletedEvent seq(int seq);

  ToolCompletedEvent ts(DateTime ts);

  ToolCompletedEvent botId(String botId);

  ToolCompletedEvent type(ToolCompletedEventTypeEnum type);

  ToolCompletedEvent payload(ToolCompletedEventPayload payload);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ToolCompletedEvent(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ToolCompletedEvent(...).copyWith(id: 12, name: "My name")
  /// ````
  ToolCompletedEvent call({
    int v,
    String runId,
    int seq,
    DateTime ts,
    String botId,
    ToolCompletedEventTypeEnum type,
    ToolCompletedEventPayload payload,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfToolCompletedEvent.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfToolCompletedEvent.copyWith.fieldName(...)`
class _$ToolCompletedEventCWProxyImpl implements _$ToolCompletedEventCWProxy {
  const _$ToolCompletedEventCWProxyImpl(this._value);

  final ToolCompletedEvent _value;

  @override
  ToolCompletedEvent v(int v) => this(v: v);

  @override
  ToolCompletedEvent runId(String runId) => this(runId: runId);

  @override
  ToolCompletedEvent seq(int seq) => this(seq: seq);

  @override
  ToolCompletedEvent ts(DateTime ts) => this(ts: ts);

  @override
  ToolCompletedEvent botId(String botId) => this(botId: botId);

  @override
  ToolCompletedEvent type(ToolCompletedEventTypeEnum type) => this(type: type);

  @override
  ToolCompletedEvent payload(ToolCompletedEventPayload payload) =>
      this(payload: payload);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ToolCompletedEvent(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ToolCompletedEvent(...).copyWith(id: 12, name: "My name")
  /// ````
  ToolCompletedEvent call({
    Object? v = const $CopyWithPlaceholder(),
    Object? runId = const $CopyWithPlaceholder(),
    Object? seq = const $CopyWithPlaceholder(),
    Object? ts = const $CopyWithPlaceholder(),
    Object? botId = const $CopyWithPlaceholder(),
    Object? type = const $CopyWithPlaceholder(),
    Object? payload = const $CopyWithPlaceholder(),
  }) {
    return ToolCompletedEvent(
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
          : type as ToolCompletedEventTypeEnum,
      payload: payload == const $CopyWithPlaceholder()
          ? _value.payload
          // ignore: cast_nullable_to_non_nullable
          : payload as ToolCompletedEventPayload,
    );
  }
}

extension $ToolCompletedEventCopyWith on ToolCompletedEvent {
  /// Returns a callable class that can be used as follows: `instanceOfToolCompletedEvent.copyWith(...)` or like so:`instanceOfToolCompletedEvent.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ToolCompletedEventCWProxy get copyWith =>
      _$ToolCompletedEventCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ToolCompletedEvent _$ToolCompletedEventFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ToolCompletedEvent', json, ($checkedConvert) {
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
      final val = ToolCompletedEvent(
        v: $checkedConvert('v', (v) => (v as num).toInt()),
        runId: $checkedConvert('run_id', (v) => v as String),
        seq: $checkedConvert('seq', (v) => (v as num).toInt()),
        ts: $checkedConvert('ts', (v) => DateTime.parse(v as String)),
        botId: $checkedConvert('bot_id', (v) => v as String),
        type: $checkedConvert(
          'type',
          (v) => $enumDecode(_$ToolCompletedEventTypeEnumEnumMap, v),
        ),
        payload: $checkedConvert(
          'payload',
          (v) => ToolCompletedEventPayload.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    }, fieldKeyMap: const {'runId': 'run_id', 'botId': 'bot_id'});

Map<String, dynamic> _$ToolCompletedEventToJson(ToolCompletedEvent instance) =>
    <String, dynamic>{
      'v': instance.v,
      'run_id': instance.runId,
      'seq': instance.seq,
      'ts': instance.ts.toIso8601String(),
      'bot_id': instance.botId,
      'type': _$ToolCompletedEventTypeEnumEnumMap[instance.type]!,
      'payload': instance.payload.toJson(),
    };

const _$ToolCompletedEventTypeEnumEnumMap = {
  ToolCompletedEventTypeEnum.toolPeriodCompleted: 'tool.completed',
};
