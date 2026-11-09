// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tool_failed_event.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ToolFailedEventCWProxy {
  ToolFailedEvent v(int v);

  ToolFailedEvent runId(String runId);

  ToolFailedEvent seq(int seq);

  ToolFailedEvent ts(DateTime ts);

  ToolFailedEvent botId(String botId);

  ToolFailedEvent type(ToolFailedEventTypeEnum type);

  ToolFailedEvent payload(ToolFailedEventPayload payload);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ToolFailedEvent(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ToolFailedEvent(...).copyWith(id: 12, name: "My name")
  /// ````
  ToolFailedEvent call({
    int v,
    String runId,
    int seq,
    DateTime ts,
    String botId,
    ToolFailedEventTypeEnum type,
    ToolFailedEventPayload payload,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfToolFailedEvent.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfToolFailedEvent.copyWith.fieldName(...)`
class _$ToolFailedEventCWProxyImpl implements _$ToolFailedEventCWProxy {
  const _$ToolFailedEventCWProxyImpl(this._value);

  final ToolFailedEvent _value;

  @override
  ToolFailedEvent v(int v) => this(v: v);

  @override
  ToolFailedEvent runId(String runId) => this(runId: runId);

  @override
  ToolFailedEvent seq(int seq) => this(seq: seq);

  @override
  ToolFailedEvent ts(DateTime ts) => this(ts: ts);

  @override
  ToolFailedEvent botId(String botId) => this(botId: botId);

  @override
  ToolFailedEvent type(ToolFailedEventTypeEnum type) => this(type: type);

  @override
  ToolFailedEvent payload(ToolFailedEventPayload payload) =>
      this(payload: payload);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ToolFailedEvent(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ToolFailedEvent(...).copyWith(id: 12, name: "My name")
  /// ````
  ToolFailedEvent call({
    Object? v = const $CopyWithPlaceholder(),
    Object? runId = const $CopyWithPlaceholder(),
    Object? seq = const $CopyWithPlaceholder(),
    Object? ts = const $CopyWithPlaceholder(),
    Object? botId = const $CopyWithPlaceholder(),
    Object? type = const $CopyWithPlaceholder(),
    Object? payload = const $CopyWithPlaceholder(),
  }) {
    return ToolFailedEvent(
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
          : type as ToolFailedEventTypeEnum,
      payload: payload == const $CopyWithPlaceholder()
          ? _value.payload
          // ignore: cast_nullable_to_non_nullable
          : payload as ToolFailedEventPayload,
    );
  }
}

extension $ToolFailedEventCopyWith on ToolFailedEvent {
  /// Returns a callable class that can be used as follows: `instanceOfToolFailedEvent.copyWith(...)` or like so:`instanceOfToolFailedEvent.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ToolFailedEventCWProxy get copyWith => _$ToolFailedEventCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ToolFailedEvent _$ToolFailedEventFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ToolFailedEvent', json, ($checkedConvert) {
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
      final val = ToolFailedEvent(
        v: $checkedConvert('v', (v) => (v as num).toInt()),
        runId: $checkedConvert('run_id', (v) => v as String),
        seq: $checkedConvert('seq', (v) => (v as num).toInt()),
        ts: $checkedConvert('ts', (v) => DateTime.parse(v as String)),
        botId: $checkedConvert('bot_id', (v) => v as String),
        type: $checkedConvert(
          'type',
          (v) => $enumDecode(_$ToolFailedEventTypeEnumEnumMap, v),
        ),
        payload: $checkedConvert(
          'payload',
          (v) => ToolFailedEventPayload.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    }, fieldKeyMap: const {'runId': 'run_id', 'botId': 'bot_id'});

Map<String, dynamic> _$ToolFailedEventToJson(ToolFailedEvent instance) =>
    <String, dynamic>{
      'v': instance.v,
      'run_id': instance.runId,
      'seq': instance.seq,
      'ts': instance.ts.toIso8601String(),
      'bot_id': instance.botId,
      'type': _$ToolFailedEventTypeEnumEnumMap[instance.type]!,
      'payload': instance.payload.toJson(),
    };

const _$ToolFailedEventTypeEnumEnumMap = {
  ToolFailedEventTypeEnum.toolPeriodFailed: 'tool.failed',
};
