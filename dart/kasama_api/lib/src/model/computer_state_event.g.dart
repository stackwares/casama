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

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ComputerStateEvent(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ComputerStateEvent(...).copyWith(id: 12, name: "My name")
  /// ````
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

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfComputerStateEvent.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfComputerStateEvent.copyWith.fieldName(...)`
class _$ComputerStateEventCWProxyImpl implements _$ComputerStateEventCWProxy {
  const _$ComputerStateEventCWProxyImpl(this._value);

  final ComputerStateEvent _value;

  @override
  ComputerStateEvent v(int v) => this(v: v);

  @override
  ComputerStateEvent runId(String runId) => this(runId: runId);

  @override
  ComputerStateEvent seq(int seq) => this(seq: seq);

  @override
  ComputerStateEvent ts(DateTime ts) => this(ts: ts);

  @override
  ComputerStateEvent botId(String botId) => this(botId: botId);

  @override
  ComputerStateEvent type(ComputerStateEventTypeEnum type) => this(type: type);

  @override
  ComputerStateEvent payload(ComputerStateEventPayload payload) =>
      this(payload: payload);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `ComputerStateEvent(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// ComputerStateEvent(...).copyWith(id: 12, name: "My name")
  /// ````
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
          : type as ComputerStateEventTypeEnum,
      payload: payload == const $CopyWithPlaceholder()
          ? _value.payload
          // ignore: cast_nullable_to_non_nullable
          : payload as ComputerStateEventPayload,
    );
  }
}

extension $ComputerStateEventCopyWith on ComputerStateEvent {
  /// Returns a callable class that can be used as follows: `instanceOfComputerStateEvent.copyWith(...)` or like so:`instanceOfComputerStateEvent.copyWith.fieldName(...)`.
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
