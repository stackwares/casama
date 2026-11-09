// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tool_output_event.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ToolOutputEventCWProxy {
  ToolOutputEvent v(int v);

  ToolOutputEvent runId(String runId);

  ToolOutputEvent seq(int seq);

  ToolOutputEvent ts(DateTime ts);

  ToolOutputEvent botId(String botId);

  ToolOutputEvent type(ToolOutputEventTypeEnum type);

  ToolOutputEvent payload(ToolOutputEventPayload payload);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ToolOutputEvent(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ToolOutputEvent(...).copyWith(id: 12, name: "My name")
  /// ```
  ToolOutputEvent call({
    int v,
    String runId,
    int seq,
    DateTime ts,
    String botId,
    ToolOutputEventTypeEnum type,
    ToolOutputEventPayload payload,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfToolOutputEvent.copyWith(...)` or call `instanceOfToolOutputEvent.copyWith.fieldName(value)` for a single field.
class _$ToolOutputEventCWProxyImpl implements _$ToolOutputEventCWProxy {
  const _$ToolOutputEventCWProxyImpl(this._value);

  final ToolOutputEvent _value;

  @override
  ToolOutputEvent v(int v) => call(v: v);

  @override
  ToolOutputEvent runId(String runId) => call(runId: runId);

  @override
  ToolOutputEvent seq(int seq) => call(seq: seq);

  @override
  ToolOutputEvent ts(DateTime ts) => call(ts: ts);

  @override
  ToolOutputEvent botId(String botId) => call(botId: botId);

  @override
  ToolOutputEvent type(ToolOutputEventTypeEnum type) => call(type: type);

  @override
  ToolOutputEvent payload(ToolOutputEventPayload payload) =>
      call(payload: payload);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ToolOutputEvent(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ToolOutputEvent(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ToolOutputEvent call({
    Object? v = const $CopyWithPlaceholder(),
    Object? runId = const $CopyWithPlaceholder(),
    Object? seq = const $CopyWithPlaceholder(),
    Object? ts = const $CopyWithPlaceholder(),
    Object? botId = const $CopyWithPlaceholder(),
    Object? type = const $CopyWithPlaceholder(),
    Object? payload = const $CopyWithPlaceholder(),
  }) {
    return ToolOutputEvent(
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
          : type as ToolOutputEventTypeEnum,
      payload: payload == const $CopyWithPlaceholder() || payload == null
          ? _value.payload
          // ignore: cast_nullable_to_non_nullable
          : payload as ToolOutputEventPayload,
    );
  }
}

extension $ToolOutputEventCopyWith on ToolOutputEvent {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfToolOutputEvent.copyWith(...)` or `instanceOfToolOutputEvent.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ToolOutputEventCWProxy get copyWith => _$ToolOutputEventCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ToolOutputEvent _$ToolOutputEventFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ToolOutputEvent', json, ($checkedConvert) {
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
      final val = ToolOutputEvent(
        v: $checkedConvert('v', (v) => (v as num).toInt()),
        runId: $checkedConvert('run_id', (v) => v as String),
        seq: $checkedConvert('seq', (v) => (v as num).toInt()),
        ts: $checkedConvert('ts', (v) => DateTime.parse(v as String)),
        botId: $checkedConvert('bot_id', (v) => v as String),
        type: $checkedConvert(
          'type',
          (v) => $enumDecode(_$ToolOutputEventTypeEnumEnumMap, v),
        ),
        payload: $checkedConvert(
          'payload',
          (v) => ToolOutputEventPayload.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    }, fieldKeyMap: const {'runId': 'run_id', 'botId': 'bot_id'});

Map<String, dynamic> _$ToolOutputEventToJson(ToolOutputEvent instance) =>
    <String, dynamic>{
      'v': instance.v,
      'run_id': instance.runId,
      'seq': instance.seq,
      'ts': instance.ts.toIso8601String(),
      'bot_id': instance.botId,
      'type': _$ToolOutputEventTypeEnumEnumMap[instance.type]!,
      'payload': instance.payload.toJson(),
    };

const _$ToolOutputEventTypeEnumEnumMap = {
  ToolOutputEventTypeEnum.toolPeriodOutput: 'tool.output',
};
