// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subrun_completed_event.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SubrunCompletedEventCWProxy {
  SubrunCompletedEvent v(int v);

  SubrunCompletedEvent runId(String runId);

  SubrunCompletedEvent seq(int seq);

  SubrunCompletedEvent ts(DateTime ts);

  SubrunCompletedEvent botId(String botId);

  SubrunCompletedEvent type(SubrunCompletedEventTypeEnum type);

  SubrunCompletedEvent payload(SubrunCompletedEventPayload payload);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SubrunCompletedEvent(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SubrunCompletedEvent(...).copyWith(id: 12, name: "My name")
  /// ```
  SubrunCompletedEvent call({
    int v,
    String runId,
    int seq,
    DateTime ts,
    String botId,
    SubrunCompletedEventTypeEnum type,
    SubrunCompletedEventPayload payload,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfSubrunCompletedEvent.copyWith(...)` or call `instanceOfSubrunCompletedEvent.copyWith.fieldName(value)` for a single field.
class _$SubrunCompletedEventCWProxyImpl
    implements _$SubrunCompletedEventCWProxy {
  const _$SubrunCompletedEventCWProxyImpl(this._value);

  final SubrunCompletedEvent _value;

  @override
  SubrunCompletedEvent v(int v) => call(v: v);

  @override
  SubrunCompletedEvent runId(String runId) => call(runId: runId);

  @override
  SubrunCompletedEvent seq(int seq) => call(seq: seq);

  @override
  SubrunCompletedEvent ts(DateTime ts) => call(ts: ts);

  @override
  SubrunCompletedEvent botId(String botId) => call(botId: botId);

  @override
  SubrunCompletedEvent type(SubrunCompletedEventTypeEnum type) =>
      call(type: type);

  @override
  SubrunCompletedEvent payload(SubrunCompletedEventPayload payload) =>
      call(payload: payload);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SubrunCompletedEvent(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SubrunCompletedEvent(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  SubrunCompletedEvent call({
    Object? v = const $CopyWithPlaceholder(),
    Object? runId = const $CopyWithPlaceholder(),
    Object? seq = const $CopyWithPlaceholder(),
    Object? ts = const $CopyWithPlaceholder(),
    Object? botId = const $CopyWithPlaceholder(),
    Object? type = const $CopyWithPlaceholder(),
    Object? payload = const $CopyWithPlaceholder(),
  }) {
    return SubrunCompletedEvent(
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
          : type as SubrunCompletedEventTypeEnum,
      payload: payload == const $CopyWithPlaceholder() || payload == null
          ? _value.payload
          // ignore: cast_nullable_to_non_nullable
          : payload as SubrunCompletedEventPayload,
    );
  }
}

extension $SubrunCompletedEventCopyWith on SubrunCompletedEvent {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfSubrunCompletedEvent.copyWith(...)` or `instanceOfSubrunCompletedEvent.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SubrunCompletedEventCWProxy get copyWith =>
      _$SubrunCompletedEventCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SubrunCompletedEvent _$SubrunCompletedEventFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('SubrunCompletedEvent', json, ($checkedConvert) {
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
  final val = SubrunCompletedEvent(
    v: $checkedConvert('v', (v) => (v as num).toInt()),
    runId: $checkedConvert('run_id', (v) => v as String),
    seq: $checkedConvert('seq', (v) => (v as num).toInt()),
    ts: $checkedConvert('ts', (v) => DateTime.parse(v as String)),
    botId: $checkedConvert('bot_id', (v) => v as String),
    type: $checkedConvert(
      'type',
      (v) => $enumDecode(_$SubrunCompletedEventTypeEnumEnumMap, v),
    ),
    payload: $checkedConvert(
      'payload',
      (v) => SubrunCompletedEventPayload.fromJson(v as Map<String, dynamic>),
    ),
  );
  return val;
}, fieldKeyMap: const {'runId': 'run_id', 'botId': 'bot_id'});

Map<String, dynamic> _$SubrunCompletedEventToJson(
  SubrunCompletedEvent instance,
) => <String, dynamic>{
  'v': instance.v,
  'run_id': instance.runId,
  'seq': instance.seq,
  'ts': instance.ts.toIso8601String(),
  'bot_id': instance.botId,
  'type': _$SubrunCompletedEventTypeEnumEnumMap[instance.type]!,
  'payload': instance.payload.toJson(),
};

const _$SubrunCompletedEventTypeEnumEnumMap = {
  SubrunCompletedEventTypeEnum.subrunPeriodCompleted: 'subrun.completed',
};
