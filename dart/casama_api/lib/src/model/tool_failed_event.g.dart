// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tool_failed_event.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ToolFailedEventCWProxy {
  ToolFailedEvent v(int v);

  ToolFailedEvent runId(String runId);

  ToolFailedEvent seq(int seq);

  ToolFailedEvent ts(DateTime ts);

  ToolFailedEvent botId(String botId);

  ToolFailedEvent type(ToolFailedEventTypeEnum type);

  ToolFailedEvent payload(ToolFailedEventPayload payload);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ToolFailedEvent(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ToolFailedEvent(...).copyWith(id: 12, name: "My name")
  /// ```
  ToolFailedEvent call({
    int v,
    String runId,
    int seq,
    DateTime ts,
    String botId,
    ToolFailedEventTypeEnum type,
    ToolFailedEventPayload payload,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfToolFailedEvent.copyWith(...)` or call `instanceOfToolFailedEvent.copyWith.fieldName(value)` for a single field.
class _$ToolFailedEventCWProxyImpl implements _$ToolFailedEventCWProxy {
  const _$ToolFailedEventCWProxyImpl(this._value);

  final ToolFailedEvent _value;

  @override
  ToolFailedEvent v(int v) => call(v: v);

  @override
  ToolFailedEvent runId(String runId) => call(runId: runId);

  @override
  ToolFailedEvent seq(int seq) => call(seq: seq);

  @override
  ToolFailedEvent ts(DateTime ts) => call(ts: ts);

  @override
  ToolFailedEvent botId(String botId) => call(botId: botId);

  @override
  ToolFailedEvent type(ToolFailedEventTypeEnum type) => call(type: type);

  @override
  ToolFailedEvent payload(ToolFailedEventPayload payload) =>
      call(payload: payload);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ToolFailedEvent(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ToolFailedEvent(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ToolFailedEvent call({
    Object? v = const $CopyWithPlaceholder(),
    Object? runId = const $CopyWithPlaceholder(),
    Object? seq = const $CopyWithPlaceholder(),
    Object? ts = const $CopyWithPlaceholder(),
    Object? botId = const $CopyWithPlaceholder(),
    Object? type = const $CopyWithPlaceholder(),
    Object? payload = const $CopyWithPlaceholder(),
  }) {
    return ToolFailedEvent(
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
          : type as ToolFailedEventTypeEnum,
      payload: payload == const $CopyWithPlaceholder() || payload == null
          ? _value.payload
          // ignore: cast_nullable_to_non_nullable
          : payload as ToolFailedEventPayload,
    );
  }
}

extension $ToolFailedEventCopyWith on ToolFailedEvent {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfToolFailedEvent.copyWith(...)` or `instanceOfToolFailedEvent.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ToolFailedEventCWProxy get copyWith => _$ToolFailedEventCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ToolFailedEvent _$ToolFailedEventFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ToolFailedEvent', json, ($checkedConvert) {
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
      final val = ToolFailedEvent(
        v: $checkedConvert('v', (v) => (v as num).toInt()),
        runId: $checkedConvert('run_id', (v) => v as String),
        seq: $checkedConvert('seq', (v) => (v as num).toInt()),
        ts: $checkedConvert('ts', (v) => DateTime.parse(v as String)),
        botId: $checkedConvert('bot_id', (v) => v as String),
        type: $checkedConvert(
          'type',
          (v) => $enumDecode(_$ToolFailedEventTypeEnumEnumMap, v),
        ),
        payload: $checkedConvert(
          'payload',
          (v) => ToolFailedEventPayload.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    }, fieldKeyMap: const {'runId': 'run_id', 'botId': 'bot_id'});

Map<String, dynamic> _$ToolFailedEventToJson(ToolFailedEvent instance) =>
    <String, dynamic>{
      'v': instance.v,
      'run_id': instance.runId,
      'seq': instance.seq,
      'ts': instance.ts.toIso8601String(),
      'bot_id': instance.botId,
      'type': _$ToolFailedEventTypeEnumEnumMap[instance.type]!,
      'payload': instance.payload.toJson(),
    };

const _$ToolFailedEventTypeEnumEnumMap = {
  ToolFailedEventTypeEnum.toolPeriodFailed: 'tool.failed',
};
