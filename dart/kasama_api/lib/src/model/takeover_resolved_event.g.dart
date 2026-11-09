// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'takeover_resolved_event.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$TakeoverResolvedEventCWProxy {
  TakeoverResolvedEvent v(int v);

  TakeoverResolvedEvent runId(String runId);

  TakeoverResolvedEvent seq(int seq);

  TakeoverResolvedEvent ts(DateTime ts);

  TakeoverResolvedEvent botId(String botId);

  TakeoverResolvedEvent type(TakeoverResolvedEventTypeEnum type);

  TakeoverResolvedEvent payload(TakeoverResolvedEventPayload payload);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `TakeoverResolvedEvent(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// TakeoverResolvedEvent(...).copyWith(id: 12, name: "My name")
  /// ````
  TakeoverResolvedEvent call({
    int v,
    String runId,
    int seq,
    DateTime ts,
    String botId,
    TakeoverResolvedEventTypeEnum type,
    TakeoverResolvedEventPayload payload,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfTakeoverResolvedEvent.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfTakeoverResolvedEvent.copyWith.fieldName(...)`
class _$TakeoverResolvedEventCWProxyImpl
    implements _$TakeoverResolvedEventCWProxy {
  const _$TakeoverResolvedEventCWProxyImpl(this._value);

  final TakeoverResolvedEvent _value;

  @override
  TakeoverResolvedEvent v(int v) => this(v: v);

  @override
  TakeoverResolvedEvent runId(String runId) => this(runId: runId);

  @override
  TakeoverResolvedEvent seq(int seq) => this(seq: seq);

  @override
  TakeoverResolvedEvent ts(DateTime ts) => this(ts: ts);

  @override
  TakeoverResolvedEvent botId(String botId) => this(botId: botId);

  @override
  TakeoverResolvedEvent type(TakeoverResolvedEventTypeEnum type) =>
      this(type: type);

  @override
  TakeoverResolvedEvent payload(TakeoverResolvedEventPayload payload) =>
      this(payload: payload);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `TakeoverResolvedEvent(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// TakeoverResolvedEvent(...).copyWith(id: 12, name: "My name")
  /// ````
  TakeoverResolvedEvent call({
    Object? v = const $CopyWithPlaceholder(),
    Object? runId = const $CopyWithPlaceholder(),
    Object? seq = const $CopyWithPlaceholder(),
    Object? ts = const $CopyWithPlaceholder(),
    Object? botId = const $CopyWithPlaceholder(),
    Object? type = const $CopyWithPlaceholder(),
    Object? payload = const $CopyWithPlaceholder(),
  }) {
    return TakeoverResolvedEvent(
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
          : type as TakeoverResolvedEventTypeEnum,
      payload: payload == const $CopyWithPlaceholder()
          ? _value.payload
          // ignore: cast_nullable_to_non_nullable
          : payload as TakeoverResolvedEventPayload,
    );
  }
}

extension $TakeoverResolvedEventCopyWith on TakeoverResolvedEvent {
  /// Returns a callable class that can be used as follows: `instanceOfTakeoverResolvedEvent.copyWith(...)` or like so:`instanceOfTakeoverResolvedEvent.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$TakeoverResolvedEventCWProxy get copyWith =>
      _$TakeoverResolvedEventCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TakeoverResolvedEvent _$TakeoverResolvedEventFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'TakeoverResolvedEvent',
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
    final val = TakeoverResolvedEvent(
      v: $checkedConvert('v', (v) => (v as num).toInt()),
      runId: $checkedConvert('run_id', (v) => v as String),
      seq: $checkedConvert('seq', (v) => (v as num).toInt()),
      ts: $checkedConvert('ts', (v) => DateTime.parse(v as String)),
      botId: $checkedConvert('bot_id', (v) => v as String),
      type: $checkedConvert(
        'type',
        (v) => $enumDecode(_$TakeoverResolvedEventTypeEnumEnumMap, v),
      ),
      payload: $checkedConvert(
        'payload',
        (v) => TakeoverResolvedEventPayload.fromJson(v as Map<String, dynamic>),
      ),
    );
    return val;
  },
  fieldKeyMap: const {'runId': 'run_id', 'botId': 'bot_id'},
);

Map<String, dynamic> _$TakeoverResolvedEventToJson(
  TakeoverResolvedEvent instance,
) => <String, dynamic>{
  'v': instance.v,
  'run_id': instance.runId,
  'seq': instance.seq,
  'ts': instance.ts.toIso8601String(),
  'bot_id': instance.botId,
  'type': _$TakeoverResolvedEventTypeEnumEnumMap[instance.type]!,
  'payload': instance.payload.toJson(),
};

const _$TakeoverResolvedEventTypeEnumEnumMap = {
  TakeoverResolvedEventTypeEnum.takeoverPeriodResolved: 'takeover.resolved',
};
