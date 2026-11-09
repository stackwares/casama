// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'usage_event.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$UsageEventCWProxy {
  UsageEvent v(int v);

  UsageEvent runId(String runId);

  UsageEvent seq(int seq);

  UsageEvent ts(DateTime ts);

  UsageEvent botId(String botId);

  UsageEvent type(UsageEventTypeEnum type);

  UsageEvent payload(UsageEventPayload payload);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `UsageEvent(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// UsageEvent(...).copyWith(id: 12, name: "My name")
  /// ````
  UsageEvent call({
    int v,
    String runId,
    int seq,
    DateTime ts,
    String botId,
    UsageEventTypeEnum type,
    UsageEventPayload payload,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfUsageEvent.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfUsageEvent.copyWith.fieldName(...)`
class _$UsageEventCWProxyImpl implements _$UsageEventCWProxy {
  const _$UsageEventCWProxyImpl(this._value);

  final UsageEvent _value;

  @override
  UsageEvent v(int v) => this(v: v);

  @override
  UsageEvent runId(String runId) => this(runId: runId);

  @override
  UsageEvent seq(int seq) => this(seq: seq);

  @override
  UsageEvent ts(DateTime ts) => this(ts: ts);

  @override
  UsageEvent botId(String botId) => this(botId: botId);

  @override
  UsageEvent type(UsageEventTypeEnum type) => this(type: type);

  @override
  UsageEvent payload(UsageEventPayload payload) => this(payload: payload);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `UsageEvent(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// UsageEvent(...).copyWith(id: 12, name: "My name")
  /// ````
  UsageEvent call({
    Object? v = const $CopyWithPlaceholder(),
    Object? runId = const $CopyWithPlaceholder(),
    Object? seq = const $CopyWithPlaceholder(),
    Object? ts = const $CopyWithPlaceholder(),
    Object? botId = const $CopyWithPlaceholder(),
    Object? type = const $CopyWithPlaceholder(),
    Object? payload = const $CopyWithPlaceholder(),
  }) {
    return UsageEvent(
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
          : type as UsageEventTypeEnum,
      payload: payload == const $CopyWithPlaceholder()
          ? _value.payload
          // ignore: cast_nullable_to_non_nullable
          : payload as UsageEventPayload,
    );
  }
}

extension $UsageEventCopyWith on UsageEvent {
  /// Returns a callable class that can be used as follows: `instanceOfUsageEvent.copyWith(...)` or like so:`instanceOfUsageEvent.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$UsageEventCWProxy get copyWith => _$UsageEventCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UsageEvent _$UsageEventFromJson(Map<String, dynamic> json) =>
    $checkedCreate('UsageEvent', json, ($checkedConvert) {
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
      final val = UsageEvent(
        v: $checkedConvert('v', (v) => (v as num).toInt()),
        runId: $checkedConvert('run_id', (v) => v as String),
        seq: $checkedConvert('seq', (v) => (v as num).toInt()),
        ts: $checkedConvert('ts', (v) => DateTime.parse(v as String)),
        botId: $checkedConvert('bot_id', (v) => v as String),
        type: $checkedConvert(
          'type',
          (v) => $enumDecode(_$UsageEventTypeEnumEnumMap, v),
        ),
        payload: $checkedConvert(
          'payload',
          (v) => UsageEventPayload.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    }, fieldKeyMap: const {'runId': 'run_id', 'botId': 'bot_id'});

Map<String, dynamic> _$UsageEventToJson(UsageEvent instance) =>
    <String, dynamic>{
      'v': instance.v,
      'run_id': instance.runId,
      'seq': instance.seq,
      'ts': instance.ts.toIso8601String(),
      'bot_id': instance.botId,
      'type': _$UsageEventTypeEnumEnumMap[instance.type]!,
      'payload': instance.payload.toJson(),
    };

const _$UsageEventTypeEnumEnumMap = {UsageEventTypeEnum.usage: 'usage'};
