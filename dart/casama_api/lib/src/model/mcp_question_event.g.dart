// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mcp_question_event.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$McpQuestionEventCWProxy {
  McpQuestionEvent v(int v);

  McpQuestionEvent runId(String runId);

  McpQuestionEvent seq(int seq);

  McpQuestionEvent ts(DateTime ts);

  McpQuestionEvent botId(String botId);

  McpQuestionEvent type(McpQuestionEventTypeEnum type);

  McpQuestionEvent payload(McpQuestionEventPayload payload);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `McpQuestionEvent(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// McpQuestionEvent(...).copyWith(id: 12, name: "My name")
  /// ```
  McpQuestionEvent call({
    int v,
    String runId,
    int seq,
    DateTime ts,
    String botId,
    McpQuestionEventTypeEnum type,
    McpQuestionEventPayload payload,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfMcpQuestionEvent.copyWith(...)` or call `instanceOfMcpQuestionEvent.copyWith.fieldName(value)` for a single field.
class _$McpQuestionEventCWProxyImpl implements _$McpQuestionEventCWProxy {
  const _$McpQuestionEventCWProxyImpl(this._value);

  final McpQuestionEvent _value;

  @override
  McpQuestionEvent v(int v) => call(v: v);

  @override
  McpQuestionEvent runId(String runId) => call(runId: runId);

  @override
  McpQuestionEvent seq(int seq) => call(seq: seq);

  @override
  McpQuestionEvent ts(DateTime ts) => call(ts: ts);

  @override
  McpQuestionEvent botId(String botId) => call(botId: botId);

  @override
  McpQuestionEvent type(McpQuestionEventTypeEnum type) => call(type: type);

  @override
  McpQuestionEvent payload(McpQuestionEventPayload payload) =>
      call(payload: payload);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `McpQuestionEvent(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// McpQuestionEvent(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  McpQuestionEvent call({
    Object? v = const $CopyWithPlaceholder(),
    Object? runId = const $CopyWithPlaceholder(),
    Object? seq = const $CopyWithPlaceholder(),
    Object? ts = const $CopyWithPlaceholder(),
    Object? botId = const $CopyWithPlaceholder(),
    Object? type = const $CopyWithPlaceholder(),
    Object? payload = const $CopyWithPlaceholder(),
  }) {
    return McpQuestionEvent(
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
          : type as McpQuestionEventTypeEnum,
      payload: payload == const $CopyWithPlaceholder() || payload == null
          ? _value.payload
          // ignore: cast_nullable_to_non_nullable
          : payload as McpQuestionEventPayload,
    );
  }
}

extension $McpQuestionEventCopyWith on McpQuestionEvent {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfMcpQuestionEvent.copyWith(...)` or `instanceOfMcpQuestionEvent.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$McpQuestionEventCWProxy get copyWith => _$McpQuestionEventCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

McpQuestionEvent _$McpQuestionEventFromJson(Map<String, dynamic> json) =>
    $checkedCreate('McpQuestionEvent', json, ($checkedConvert) {
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
      final val = McpQuestionEvent(
        v: $checkedConvert('v', (v) => (v as num).toInt()),
        runId: $checkedConvert('run_id', (v) => v as String),
        seq: $checkedConvert('seq', (v) => (v as num).toInt()),
        ts: $checkedConvert('ts', (v) => DateTime.parse(v as String)),
        botId: $checkedConvert('bot_id', (v) => v as String),
        type: $checkedConvert(
          'type',
          (v) => $enumDecode(_$McpQuestionEventTypeEnumEnumMap, v),
        ),
        payload: $checkedConvert(
          'payload',
          (v) => McpQuestionEventPayload.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    }, fieldKeyMap: const {'runId': 'run_id', 'botId': 'bot_id'});

Map<String, dynamic> _$McpQuestionEventToJson(McpQuestionEvent instance) =>
    <String, dynamic>{
      'v': instance.v,
      'run_id': instance.runId,
      'seq': instance.seq,
      'ts': instance.ts.toIso8601String(),
      'bot_id': instance.botId,
      'type': _$McpQuestionEventTypeEnumEnumMap[instance.type]!,
      'payload': instance.payload.toJson(),
    };

const _$McpQuestionEventTypeEnumEnumMap = {
  McpQuestionEventTypeEnum.mcpPeriodQuestion: 'mcp.question',
};
