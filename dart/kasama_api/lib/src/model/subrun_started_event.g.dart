// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subrun_started_event.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SubrunStartedEventCWProxy {
  SubrunStartedEvent v(int v);

  SubrunStartedEvent runId(String runId);

  SubrunStartedEvent seq(int seq);

  SubrunStartedEvent ts(DateTime ts);

  SubrunStartedEvent botId(String botId);

  SubrunStartedEvent type(SubrunStartedEventTypeEnum type);

  SubrunStartedEvent payload(SubrunStartedEventPayload payload);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `SubrunStartedEvent(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// SubrunStartedEvent(...).copyWith(id: 12, name: "My name")
  /// ````
  SubrunStartedEvent call({
    int v,
    String runId,
    int seq,
    DateTime ts,
    String botId,
    SubrunStartedEventTypeEnum type,
    SubrunStartedEventPayload payload,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfSubrunStartedEvent.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfSubrunStartedEvent.copyWith.fieldName(...)`
class _$SubrunStartedEventCWProxyImpl implements _$SubrunStartedEventCWProxy {
  const _$SubrunStartedEventCWProxyImpl(this._value);

  final SubrunStartedEvent _value;

  @override
  SubrunStartedEvent v(int v) => this(v: v);

  @override
  SubrunStartedEvent runId(String runId) => this(runId: runId);

  @override
  SubrunStartedEvent seq(int seq) => this(seq: seq);

  @override
  SubrunStartedEvent ts(DateTime ts) => this(ts: ts);

  @override
  SubrunStartedEvent botId(String botId) => this(botId: botId);

  @override
  SubrunStartedEvent type(SubrunStartedEventTypeEnum type) => this(type: type);

  @override
  SubrunStartedEvent payload(SubrunStartedEventPayload payload) =>
      this(payload: payload);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `SubrunStartedEvent(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// SubrunStartedEvent(...).copyWith(id: 12, name: "My name")
  /// ````
  SubrunStartedEvent call({
    Object? v = const $CopyWithPlaceholder(),
    Object? runId = const $CopyWithPlaceholder(),
    Object? seq = const $CopyWithPlaceholder(),
    Object? ts = const $CopyWithPlaceholder(),
    Object? botId = const $CopyWithPlaceholder(),
    Object? type = const $CopyWithPlaceholder(),
    Object? payload = const $CopyWithPlaceholder(),
  }) {
    return SubrunStartedEvent(
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
          : type as SubrunStartedEventTypeEnum,
      payload: payload == const $CopyWithPlaceholder()
          ? _value.payload
          // ignore: cast_nullable_to_non_nullable
          : payload as SubrunStartedEventPayload,
    );
  }
}

extension $SubrunStartedEventCopyWith on SubrunStartedEvent {
  /// Returns a callable class that can be used as follows: `instanceOfSubrunStartedEvent.copyWith(...)` or like so:`instanceOfSubrunStartedEvent.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SubrunStartedEventCWProxy get copyWith =>
      _$SubrunStartedEventCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SubrunStartedEvent _$SubrunStartedEventFromJson(Map<String, dynamic> json) =>
    $checkedCreate('SubrunStartedEvent', json, ($checkedConvert) {
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
      final val = SubrunStartedEvent(
        v: $checkedConvert('v', (v) => (v as num).toInt()),
        runId: $checkedConvert('run_id', (v) => v as String),
        seq: $checkedConvert('seq', (v) => (v as num).toInt()),
        ts: $checkedConvert('ts', (v) => DateTime.parse(v as String)),
        botId: $checkedConvert('bot_id', (v) => v as String),
        type: $checkedConvert(
          'type',
          (v) => $enumDecode(_$SubrunStartedEventTypeEnumEnumMap, v),
        ),
        payload: $checkedConvert(
          'payload',
          (v) => SubrunStartedEventPayload.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    }, fieldKeyMap: const {'runId': 'run_id', 'botId': 'bot_id'});

Map<String, dynamic> _$SubrunStartedEventToJson(SubrunStartedEvent instance) =>
    <String, dynamic>{
      'v': instance.v,
      'run_id': instance.runId,
      'seq': instance.seq,
      'ts': instance.ts.toIso8601String(),
      'bot_id': instance.botId,
      'type': _$SubrunStartedEventTypeEnumEnumMap[instance.type]!,
      'payload': instance.payload.toJson(),
    };

const _$SubrunStartedEventTypeEnumEnumMap = {
  SubrunStartedEventTypeEnum.subrunPeriodStarted: 'subrun.started',
};
