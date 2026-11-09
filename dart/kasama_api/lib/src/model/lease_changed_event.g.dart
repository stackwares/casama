// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lease_changed_event.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$LeaseChangedEventCWProxy {
  LeaseChangedEvent v(int v);

  LeaseChangedEvent runId(String runId);

  LeaseChangedEvent seq(int seq);

  LeaseChangedEvent ts(DateTime ts);

  LeaseChangedEvent botId(String botId);

  LeaseChangedEvent type(LeaseChangedEventTypeEnum type);

  LeaseChangedEvent payload(LeaseChangedEventPayload payload);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `LeaseChangedEvent(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// LeaseChangedEvent(...).copyWith(id: 12, name: "My name")
  /// ````
  LeaseChangedEvent call({
    int v,
    String runId,
    int seq,
    DateTime ts,
    String botId,
    LeaseChangedEventTypeEnum type,
    LeaseChangedEventPayload payload,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfLeaseChangedEvent.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfLeaseChangedEvent.copyWith.fieldName(...)`
class _$LeaseChangedEventCWProxyImpl implements _$LeaseChangedEventCWProxy {
  const _$LeaseChangedEventCWProxyImpl(this._value);

  final LeaseChangedEvent _value;

  @override
  LeaseChangedEvent v(int v) => this(v: v);

  @override
  LeaseChangedEvent runId(String runId) => this(runId: runId);

  @override
  LeaseChangedEvent seq(int seq) => this(seq: seq);

  @override
  LeaseChangedEvent ts(DateTime ts) => this(ts: ts);

  @override
  LeaseChangedEvent botId(String botId) => this(botId: botId);

  @override
  LeaseChangedEvent type(LeaseChangedEventTypeEnum type) => this(type: type);

  @override
  LeaseChangedEvent payload(LeaseChangedEventPayload payload) =>
      this(payload: payload);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `LeaseChangedEvent(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// LeaseChangedEvent(...).copyWith(id: 12, name: "My name")
  /// ````
  LeaseChangedEvent call({
    Object? v = const $CopyWithPlaceholder(),
    Object? runId = const $CopyWithPlaceholder(),
    Object? seq = const $CopyWithPlaceholder(),
    Object? ts = const $CopyWithPlaceholder(),
    Object? botId = const $CopyWithPlaceholder(),
    Object? type = const $CopyWithPlaceholder(),
    Object? payload = const $CopyWithPlaceholder(),
  }) {
    return LeaseChangedEvent(
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
          : type as LeaseChangedEventTypeEnum,
      payload: payload == const $CopyWithPlaceholder()
          ? _value.payload
          // ignore: cast_nullable_to_non_nullable
          : payload as LeaseChangedEventPayload,
    );
  }
}

extension $LeaseChangedEventCopyWith on LeaseChangedEvent {
  /// Returns a callable class that can be used as follows: `instanceOfLeaseChangedEvent.copyWith(...)` or like so:`instanceOfLeaseChangedEvent.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$LeaseChangedEventCWProxy get copyWith =>
      _$LeaseChangedEventCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LeaseChangedEvent _$LeaseChangedEventFromJson(Map<String, dynamic> json) =>
    $checkedCreate('LeaseChangedEvent', json, ($checkedConvert) {
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
      final val = LeaseChangedEvent(
        v: $checkedConvert('v', (v) => (v as num).toInt()),
        runId: $checkedConvert('run_id', (v) => v as String),
        seq: $checkedConvert('seq', (v) => (v as num).toInt()),
        ts: $checkedConvert('ts', (v) => DateTime.parse(v as String)),
        botId: $checkedConvert('bot_id', (v) => v as String),
        type: $checkedConvert(
          'type',
          (v) => $enumDecode(_$LeaseChangedEventTypeEnumEnumMap, v),
        ),
        payload: $checkedConvert(
          'payload',
          (v) => LeaseChangedEventPayload.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    }, fieldKeyMap: const {'runId': 'run_id', 'botId': 'bot_id'});

Map<String, dynamic> _$LeaseChangedEventToJson(LeaseChangedEvent instance) =>
    <String, dynamic>{
      'v': instance.v,
      'run_id': instance.runId,
      'seq': instance.seq,
      'ts': instance.ts.toIso8601String(),
      'bot_id': instance.botId,
      'type': _$LeaseChangedEventTypeEnumEnumMap[instance.type]!,
      'payload': instance.payload.toJson(),
    };

const _$LeaseChangedEventTypeEnumEnumMap = {
  LeaseChangedEventTypeEnum.leasePeriodChanged: 'lease.changed',
};
