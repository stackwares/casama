// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'takeover_requested_event.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$TakeoverRequestedEventCWProxy {
  TakeoverRequestedEvent v(int v);

  TakeoverRequestedEvent runId(String runId);

  TakeoverRequestedEvent seq(int seq);

  TakeoverRequestedEvent ts(DateTime ts);

  TakeoverRequestedEvent botId(String botId);

  TakeoverRequestedEvent type(TakeoverRequestedEventTypeEnum type);

  TakeoverRequestedEvent payload(TakeoverRequestedEventPayload payload);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `TakeoverRequestedEvent(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// TakeoverRequestedEvent(...).copyWith(id: 12, name: "My name")
  /// ````
  TakeoverRequestedEvent call({
    int v,
    String runId,
    int seq,
    DateTime ts,
    String botId,
    TakeoverRequestedEventTypeEnum type,
    TakeoverRequestedEventPayload payload,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfTakeoverRequestedEvent.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfTakeoverRequestedEvent.copyWith.fieldName(...)`
class _$TakeoverRequestedEventCWProxyImpl
    implements _$TakeoverRequestedEventCWProxy {
  const _$TakeoverRequestedEventCWProxyImpl(this._value);

  final TakeoverRequestedEvent _value;

  @override
  TakeoverRequestedEvent v(int v) => this(v: v);

  @override
  TakeoverRequestedEvent runId(String runId) => this(runId: runId);

  @override
  TakeoverRequestedEvent seq(int seq) => this(seq: seq);

  @override
  TakeoverRequestedEvent ts(DateTime ts) => this(ts: ts);

  @override
  TakeoverRequestedEvent botId(String botId) => this(botId: botId);

  @override
  TakeoverRequestedEvent type(TakeoverRequestedEventTypeEnum type) =>
      this(type: type);

  @override
  TakeoverRequestedEvent payload(TakeoverRequestedEventPayload payload) =>
      this(payload: payload);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `TakeoverRequestedEvent(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// TakeoverRequestedEvent(...).copyWith(id: 12, name: "My name")
  /// ````
  TakeoverRequestedEvent call({
    Object? v = const $CopyWithPlaceholder(),
    Object? runId = const $CopyWithPlaceholder(),
    Object? seq = const $CopyWithPlaceholder(),
    Object? ts = const $CopyWithPlaceholder(),
    Object? botId = const $CopyWithPlaceholder(),
    Object? type = const $CopyWithPlaceholder(),
    Object? payload = const $CopyWithPlaceholder(),
  }) {
    return TakeoverRequestedEvent(
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
          : type as TakeoverRequestedEventTypeEnum,
      payload: payload == const $CopyWithPlaceholder()
          ? _value.payload
          // ignore: cast_nullable_to_non_nullable
          : payload as TakeoverRequestedEventPayload,
    );
  }
}

extension $TakeoverRequestedEventCopyWith on TakeoverRequestedEvent {
  /// Returns a callable class that can be used as follows: `instanceOfTakeoverRequestedEvent.copyWith(...)` or like so:`instanceOfTakeoverRequestedEvent.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$TakeoverRequestedEventCWProxy get copyWith =>
      _$TakeoverRequestedEventCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TakeoverRequestedEvent _$TakeoverRequestedEventFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'TakeoverRequestedEvent',
  json,
  ($checkedConvert) {
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
    final val = TakeoverRequestedEvent(
      v: $checkedConvert('v', (v) => (v as num).toInt()),
      runId: $checkedConvert('run_id', (v) => v as String),
      seq: $checkedConvert('seq', (v) => (v as num).toInt()),
      ts: $checkedConvert('ts', (v) => DateTime.parse(v as String)),
      botId: $checkedConvert('bot_id', (v) => v as String),
      type: $checkedConvert(
        'type',
        (v) => $enumDecode(_$TakeoverRequestedEventTypeEnumEnumMap, v),
      ),
      payload: $checkedConvert(
        'payload',
        (v) =>
            TakeoverRequestedEventPayload.fromJson(v as Map<String, dynamic>),
      ),
    );
    return val;
  },
  fieldKeyMap: const {'runId': 'run_id', 'botId': 'bot_id'},
);

Map<String, dynamic> _$TakeoverRequestedEventToJson(
  TakeoverRequestedEvent instance,
) => <String, dynamic>{
  'v': instance.v,
  'run_id': instance.runId,
  'seq': instance.seq,
  'ts': instance.ts.toIso8601String(),
  'bot_id': instance.botId,
  'type': _$TakeoverRequestedEventTypeEnumEnumMap[instance.type]!,
  'payload': instance.payload.toJson(),
};

const _$TakeoverRequestedEventTypeEnumEnumMap = {
  TakeoverRequestedEventTypeEnum.takeoverPeriodRequested: 'takeover.requested',
};
