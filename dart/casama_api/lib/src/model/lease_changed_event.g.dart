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

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `LeaseChangedEvent(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// LeaseChangedEvent(...).copyWith(id: 12, name: "My name")
  /// ```
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

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfLeaseChangedEvent.copyWith(...)` or call `instanceOfLeaseChangedEvent.copyWith.fieldName(value)` for a single field.
class _$LeaseChangedEventCWProxyImpl implements _$LeaseChangedEventCWProxy {
  const _$LeaseChangedEventCWProxyImpl(this._value);

  final LeaseChangedEvent _value;

  @override
  LeaseChangedEvent v(int v) => call(v: v);

  @override
  LeaseChangedEvent runId(String runId) => call(runId: runId);

  @override
  LeaseChangedEvent seq(int seq) => call(seq: seq);

  @override
  LeaseChangedEvent ts(DateTime ts) => call(ts: ts);

  @override
  LeaseChangedEvent botId(String botId) => call(botId: botId);

  @override
  LeaseChangedEvent type(LeaseChangedEventTypeEnum type) => call(type: type);

  @override
  LeaseChangedEvent payload(LeaseChangedEventPayload payload) =>
      call(payload: payload);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `LeaseChangedEvent(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// LeaseChangedEvent(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
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
          : type as LeaseChangedEventTypeEnum,
      payload: payload == const $CopyWithPlaceholder() || payload == null
          ? _value.payload
          // ignore: cast_nullable_to_non_nullable
          : payload as LeaseChangedEventPayload,
    );
  }
}

extension $LeaseChangedEventCopyWith on LeaseChangedEvent {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfLeaseChangedEvent.copyWith(...)` or `instanceOfLeaseChangedEvent.copyWith.fieldName(...)`.
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
