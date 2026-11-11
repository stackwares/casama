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

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `TakeoverResolvedEvent(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// TakeoverResolvedEvent(...).copyWith(id: 12, name: "My name")
  /// ```
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

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfTakeoverResolvedEvent.copyWith(...)` or call `instanceOfTakeoverResolvedEvent.copyWith.fieldName(value)` for a single field.
class _$TakeoverResolvedEventCWProxyImpl
    implements _$TakeoverResolvedEventCWProxy {
  const _$TakeoverResolvedEventCWProxyImpl(this._value);

  final TakeoverResolvedEvent _value;

  @override
  TakeoverResolvedEvent v(int v) => call(v: v);

  @override
  TakeoverResolvedEvent runId(String runId) => call(runId: runId);

  @override
  TakeoverResolvedEvent seq(int seq) => call(seq: seq);

  @override
  TakeoverResolvedEvent ts(DateTime ts) => call(ts: ts);

  @override
  TakeoverResolvedEvent botId(String botId) => call(botId: botId);

  @override
  TakeoverResolvedEvent type(TakeoverResolvedEventTypeEnum type) =>
      call(type: type);

  @override
  TakeoverResolvedEvent payload(TakeoverResolvedEventPayload payload) =>
      call(payload: payload);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `TakeoverResolvedEvent(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// TakeoverResolvedEvent(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
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
          : type as TakeoverResolvedEventTypeEnum,
      payload: payload == const $CopyWithPlaceholder() || payload == null
          ? _value.payload
          // ignore: cast_nullable_to_non_nullable
          : payload as TakeoverResolvedEventPayload,
    );
  }
}

extension $TakeoverResolvedEventCopyWith on TakeoverResolvedEvent {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfTakeoverResolvedEvent.copyWith(...)` or `instanceOfTakeoverResolvedEvent.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$TakeoverResolvedEventCWProxy get copyWith =>
      _$TakeoverResolvedEventCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TakeoverResolvedEvent _$TakeoverResolvedEventFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('TakeoverResolvedEvent', json, ($checkedConvert) {
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
}, fieldKeyMap: const {'runId': 'run_id', 'botId': 'bot_id'});

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
