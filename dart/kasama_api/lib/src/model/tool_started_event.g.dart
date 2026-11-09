// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tool_started_event.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ToolStartedEventCWProxy {
  ToolStartedEvent v(int v);

  ToolStartedEvent runId(String runId);

  ToolStartedEvent seq(int seq);

  ToolStartedEvent ts(DateTime ts);

  ToolStartedEvent botId(String botId);

  ToolStartedEvent type(ToolStartedEventTypeEnum type);

  ToolStartedEvent payload(ToolStartedEventPayload payload);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ToolStartedEvent(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ToolStartedEvent(...).copyWith(id: 12, name: "My name")
  /// ```
  ToolStartedEvent call({
    int v,
    String runId,
    int seq,
    DateTime ts,
    String botId,
    ToolStartedEventTypeEnum type,
    ToolStartedEventPayload payload,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfToolStartedEvent.copyWith(...)` or call `instanceOfToolStartedEvent.copyWith.fieldName(value)` for a single field.
class _$ToolStartedEventCWProxyImpl implements _$ToolStartedEventCWProxy {
  const _$ToolStartedEventCWProxyImpl(this._value);

  final ToolStartedEvent _value;

  @override
  ToolStartedEvent v(int v) => call(v: v);

  @override
  ToolStartedEvent runId(String runId) => call(runId: runId);

  @override
  ToolStartedEvent seq(int seq) => call(seq: seq);

  @override
  ToolStartedEvent ts(DateTime ts) => call(ts: ts);

  @override
  ToolStartedEvent botId(String botId) => call(botId: botId);

  @override
  ToolStartedEvent type(ToolStartedEventTypeEnum type) => call(type: type);

  @override
  ToolStartedEvent payload(ToolStartedEventPayload payload) =>
      call(payload: payload);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ToolStartedEvent(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ToolStartedEvent(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ToolStartedEvent call({
    Object? v = const $CopyWithPlaceholder(),
    Object? runId = const $CopyWithPlaceholder(),
    Object? seq = const $CopyWithPlaceholder(),
    Object? ts = const $CopyWithPlaceholder(),
    Object? botId = const $CopyWithPlaceholder(),
    Object? type = const $CopyWithPlaceholder(),
    Object? payload = const $CopyWithPlaceholder(),
  }) {
    return ToolStartedEvent(
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
          : type as ToolStartedEventTypeEnum,
      payload: payload == const $CopyWithPlaceholder() || payload == null
          ? _value.payload
          // ignore: cast_nullable_to_non_nullable
          : payload as ToolStartedEventPayload,
    );
  }
}

extension $ToolStartedEventCopyWith on ToolStartedEvent {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfToolStartedEvent.copyWith(...)` or `instanceOfToolStartedEvent.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ToolStartedEventCWProxy get copyWith => _$ToolStartedEventCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ToolStartedEvent _$ToolStartedEventFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ToolStartedEvent', json, ($checkedConvert) {
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
      final val = ToolStartedEvent(
        v: $checkedConvert('v', (v) => (v as num).toInt()),
        runId: $checkedConvert('run_id', (v) => v as String),
        seq: $checkedConvert('seq', (v) => (v as num).toInt()),
        ts: $checkedConvert('ts', (v) => DateTime.parse(v as String)),
        botId: $checkedConvert('bot_id', (v) => v as String),
        type: $checkedConvert(
          'type',
          (v) => $enumDecode(_$ToolStartedEventTypeEnumEnumMap, v),
        ),
        payload: $checkedConvert(
          'payload',
          (v) => ToolStartedEventPayload.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    }, fieldKeyMap: const {'runId': 'run_id', 'botId': 'bot_id'});

Map<String, dynamic> _$ToolStartedEventToJson(ToolStartedEvent instance) =>
    <String, dynamic>{
      'v': instance.v,
      'run_id': instance.runId,
      'seq': instance.seq,
      'ts': instance.ts.toIso8601String(),
      'bot_id': instance.botId,
      'type': _$ToolStartedEventTypeEnumEnumMap[instance.type]!,
      'payload': instance.payload.toJson(),
    };

const _$ToolStartedEventTypeEnumEnumMap = {
  ToolStartedEventTypeEnum.toolPeriodStarted: 'tool.started',
};
