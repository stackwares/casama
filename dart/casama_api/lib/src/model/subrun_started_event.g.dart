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

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SubrunStartedEvent(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SubrunStartedEvent(...).copyWith(id: 12, name: "My name")
  /// ```
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

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfSubrunStartedEvent.copyWith(...)` or call `instanceOfSubrunStartedEvent.copyWith.fieldName(value)` for a single field.
class _$SubrunStartedEventCWProxyImpl implements _$SubrunStartedEventCWProxy {
  const _$SubrunStartedEventCWProxyImpl(this._value);

  final SubrunStartedEvent _value;

  @override
  SubrunStartedEvent v(int v) => call(v: v);

  @override
  SubrunStartedEvent runId(String runId) => call(runId: runId);

  @override
  SubrunStartedEvent seq(int seq) => call(seq: seq);

  @override
  SubrunStartedEvent ts(DateTime ts) => call(ts: ts);

  @override
  SubrunStartedEvent botId(String botId) => call(botId: botId);

  @override
  SubrunStartedEvent type(SubrunStartedEventTypeEnum type) => call(type: type);

  @override
  SubrunStartedEvent payload(SubrunStartedEventPayload payload) =>
      call(payload: payload);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SubrunStartedEvent(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SubrunStartedEvent(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
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
          : type as SubrunStartedEventTypeEnum,
      payload: payload == const $CopyWithPlaceholder() || payload == null
          ? _value.payload
          // ignore: cast_nullable_to_non_nullable
          : payload as SubrunStartedEventPayload,
    );
  }
}

extension $SubrunStartedEventCopyWith on SubrunStartedEvent {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfSubrunStartedEvent.copyWith(...)` or `instanceOfSubrunStartedEvent.copyWith.fieldName(...)`.
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
