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

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `TakeoverRequestedEvent(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// TakeoverRequestedEvent(...).copyWith(id: 12, name: "My name")
  /// ```
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

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfTakeoverRequestedEvent.copyWith(...)` or call `instanceOfTakeoverRequestedEvent.copyWith.fieldName(value)` for a single field.
class _$TakeoverRequestedEventCWProxyImpl
    implements _$TakeoverRequestedEventCWProxy {
  const _$TakeoverRequestedEventCWProxyImpl(this._value);

  final TakeoverRequestedEvent _value;

  @override
  TakeoverRequestedEvent v(int v) => call(v: v);

  @override
  TakeoverRequestedEvent runId(String runId) => call(runId: runId);

  @override
  TakeoverRequestedEvent seq(int seq) => call(seq: seq);

  @override
  TakeoverRequestedEvent ts(DateTime ts) => call(ts: ts);

  @override
  TakeoverRequestedEvent botId(String botId) => call(botId: botId);

  @override
  TakeoverRequestedEvent type(TakeoverRequestedEventTypeEnum type) =>
      call(type: type);

  @override
  TakeoverRequestedEvent payload(TakeoverRequestedEventPayload payload) =>
      call(payload: payload);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `TakeoverRequestedEvent(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// TakeoverRequestedEvent(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
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
          : type as TakeoverRequestedEventTypeEnum,
      payload: payload == const $CopyWithPlaceholder() || payload == null
          ? _value.payload
          // ignore: cast_nullable_to_non_nullable
          : payload as TakeoverRequestedEventPayload,
    );
  }
}

extension $TakeoverRequestedEventCopyWith on TakeoverRequestedEvent {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfTakeoverRequestedEvent.copyWith(...)` or `instanceOfTakeoverRequestedEvent.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$TakeoverRequestedEventCWProxy get copyWith =>
      _$TakeoverRequestedEventCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TakeoverRequestedEvent _$TakeoverRequestedEventFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('TakeoverRequestedEvent', json, ($checkedConvert) {
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
      (v) => TakeoverRequestedEventPayload.fromJson(v as Map<String, dynamic>),
    ),
  );
  return val;
}, fieldKeyMap: const {'runId': 'run_id', 'botId': 'bot_id'});

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
