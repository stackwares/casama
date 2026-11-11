// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message_delta_event.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$MessageDeltaEventCWProxy {
  MessageDeltaEvent v(int v);

  MessageDeltaEvent runId(String runId);

  MessageDeltaEvent seq(int seq);

  MessageDeltaEvent ts(DateTime ts);

  MessageDeltaEvent botId(String botId);

  MessageDeltaEvent type(MessageDeltaEventTypeEnum type);

  MessageDeltaEvent payload(MessageDeltaEventPayload payload);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `MessageDeltaEvent(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// MessageDeltaEvent(...).copyWith(id: 12, name: "My name")
  /// ```
  MessageDeltaEvent call({
    int v,
    String runId,
    int seq,
    DateTime ts,
    String botId,
    MessageDeltaEventTypeEnum type,
    MessageDeltaEventPayload payload,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfMessageDeltaEvent.copyWith(...)` or call `instanceOfMessageDeltaEvent.copyWith.fieldName(value)` for a single field.
class _$MessageDeltaEventCWProxyImpl implements _$MessageDeltaEventCWProxy {
  const _$MessageDeltaEventCWProxyImpl(this._value);

  final MessageDeltaEvent _value;

  @override
  MessageDeltaEvent v(int v) => call(v: v);

  @override
  MessageDeltaEvent runId(String runId) => call(runId: runId);

  @override
  MessageDeltaEvent seq(int seq) => call(seq: seq);

  @override
  MessageDeltaEvent ts(DateTime ts) => call(ts: ts);

  @override
  MessageDeltaEvent botId(String botId) => call(botId: botId);

  @override
  MessageDeltaEvent type(MessageDeltaEventTypeEnum type) => call(type: type);

  @override
  MessageDeltaEvent payload(MessageDeltaEventPayload payload) =>
      call(payload: payload);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `MessageDeltaEvent(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// MessageDeltaEvent(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  MessageDeltaEvent call({
    Object? v = const $CopyWithPlaceholder(),
    Object? runId = const $CopyWithPlaceholder(),
    Object? seq = const $CopyWithPlaceholder(),
    Object? ts = const $CopyWithPlaceholder(),
    Object? botId = const $CopyWithPlaceholder(),
    Object? type = const $CopyWithPlaceholder(),
    Object? payload = const $CopyWithPlaceholder(),
  }) {
    return MessageDeltaEvent(
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
          : type as MessageDeltaEventTypeEnum,
      payload: payload == const $CopyWithPlaceholder() || payload == null
          ? _value.payload
          // ignore: cast_nullable_to_non_nullable
          : payload as MessageDeltaEventPayload,
    );
  }
}

extension $MessageDeltaEventCopyWith on MessageDeltaEvent {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfMessageDeltaEvent.copyWith(...)` or `instanceOfMessageDeltaEvent.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$MessageDeltaEventCWProxy get copyWith =>
      _$MessageDeltaEventCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MessageDeltaEvent _$MessageDeltaEventFromJson(Map<String, dynamic> json) =>
    $checkedCreate('MessageDeltaEvent', json, ($checkedConvert) {
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
      final val = MessageDeltaEvent(
        v: $checkedConvert('v', (v) => (v as num).toInt()),
        runId: $checkedConvert('run_id', (v) => v as String),
        seq: $checkedConvert('seq', (v) => (v as num).toInt()),
        ts: $checkedConvert('ts', (v) => DateTime.parse(v as String)),
        botId: $checkedConvert('bot_id', (v) => v as String),
        type: $checkedConvert(
          'type',
          (v) => $enumDecode(_$MessageDeltaEventTypeEnumEnumMap, v),
        ),
        payload: $checkedConvert(
          'payload',
          (v) => MessageDeltaEventPayload.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    }, fieldKeyMap: const {'runId': 'run_id', 'botId': 'bot_id'});

Map<String, dynamic> _$MessageDeltaEventToJson(MessageDeltaEvent instance) =>
    <String, dynamic>{
      'v': instance.v,
      'run_id': instance.runId,
      'seq': instance.seq,
      'ts': instance.ts.toIso8601String(),
      'bot_id': instance.botId,
      'type': _$MessageDeltaEventTypeEnumEnumMap[instance.type]!,
      'payload': instance.payload.toJson(),
    };

const _$MessageDeltaEventTypeEnumEnumMap = {
  MessageDeltaEventTypeEnum.messagePeriodDelta: 'message.delta',
};
