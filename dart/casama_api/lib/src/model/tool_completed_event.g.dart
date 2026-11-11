// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tool_completed_event.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ToolCompletedEventCWProxy {
  ToolCompletedEvent v(int v);

  ToolCompletedEvent runId(String runId);

  ToolCompletedEvent seq(int seq);

  ToolCompletedEvent ts(DateTime ts);

  ToolCompletedEvent botId(String botId);

  ToolCompletedEvent type(ToolCompletedEventTypeEnum type);

  ToolCompletedEvent payload(ToolCompletedEventPayload payload);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ToolCompletedEvent(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ToolCompletedEvent(...).copyWith(id: 12, name: "My name")
  /// ```
  ToolCompletedEvent call({
    int v,
    String runId,
    int seq,
    DateTime ts,
    String botId,
    ToolCompletedEventTypeEnum type,
    ToolCompletedEventPayload payload,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfToolCompletedEvent.copyWith(...)` or call `instanceOfToolCompletedEvent.copyWith.fieldName(value)` for a single field.
class _$ToolCompletedEventCWProxyImpl implements _$ToolCompletedEventCWProxy {
  const _$ToolCompletedEventCWProxyImpl(this._value);

  final ToolCompletedEvent _value;

  @override
  ToolCompletedEvent v(int v) => call(v: v);

  @override
  ToolCompletedEvent runId(String runId) => call(runId: runId);

  @override
  ToolCompletedEvent seq(int seq) => call(seq: seq);

  @override
  ToolCompletedEvent ts(DateTime ts) => call(ts: ts);

  @override
  ToolCompletedEvent botId(String botId) => call(botId: botId);

  @override
  ToolCompletedEvent type(ToolCompletedEventTypeEnum type) => call(type: type);

  @override
  ToolCompletedEvent payload(ToolCompletedEventPayload payload) =>
      call(payload: payload);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ToolCompletedEvent(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ToolCompletedEvent(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ToolCompletedEvent call({
    Object? v = const $CopyWithPlaceholder(),
    Object? runId = const $CopyWithPlaceholder(),
    Object? seq = const $CopyWithPlaceholder(),
    Object? ts = const $CopyWithPlaceholder(),
    Object? botId = const $CopyWithPlaceholder(),
    Object? type = const $CopyWithPlaceholder(),
    Object? payload = const $CopyWithPlaceholder(),
  }) {
    return ToolCompletedEvent(
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
          : type as ToolCompletedEventTypeEnum,
      payload: payload == const $CopyWithPlaceholder() || payload == null
          ? _value.payload
          // ignore: cast_nullable_to_non_nullable
          : payload as ToolCompletedEventPayload,
    );
  }
}

extension $ToolCompletedEventCopyWith on ToolCompletedEvent {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfToolCompletedEvent.copyWith(...)` or `instanceOfToolCompletedEvent.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ToolCompletedEventCWProxy get copyWith =>
      _$ToolCompletedEventCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ToolCompletedEvent _$ToolCompletedEventFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ToolCompletedEvent', json, ($checkedConvert) {
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
      final val = ToolCompletedEvent(
        v: $checkedConvert('v', (v) => (v as num).toInt()),
        runId: $checkedConvert('run_id', (v) => v as String),
        seq: $checkedConvert('seq', (v) => (v as num).toInt()),
        ts: $checkedConvert('ts', (v) => DateTime.parse(v as String)),
        botId: $checkedConvert('bot_id', (v) => v as String),
        type: $checkedConvert(
          'type',
          (v) => $enumDecode(_$ToolCompletedEventTypeEnumEnumMap, v),
        ),
        payload: $checkedConvert(
          'payload',
          (v) => ToolCompletedEventPayload.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    }, fieldKeyMap: const {'runId': 'run_id', 'botId': 'bot_id'});

Map<String, dynamic> _$ToolCompletedEventToJson(ToolCompletedEvent instance) =>
    <String, dynamic>{
      'v': instance.v,
      'run_id': instance.runId,
      'seq': instance.seq,
      'ts': instance.ts.toIso8601String(),
      'bot_id': instance.botId,
      'type': _$ToolCompletedEventTypeEnumEnumMap[instance.type]!,
      'payload': instance.payload.toJson(),
    };

const _$ToolCompletedEventTypeEnumEnumMap = {
  ToolCompletedEventTypeEnum.toolPeriodCompleted: 'tool.completed',
};
