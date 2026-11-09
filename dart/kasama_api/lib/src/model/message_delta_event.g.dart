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

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `MessageDeltaEvent(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// MessageDeltaEvent(...).copyWith(id: 12, name: "My name")
  /// ````
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

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfMessageDeltaEvent.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfMessageDeltaEvent.copyWith.fieldName(...)`
class _$MessageDeltaEventCWProxyImpl implements _$MessageDeltaEventCWProxy {
  const _$MessageDeltaEventCWProxyImpl(this._value);

  final MessageDeltaEvent _value;

  @override
  MessageDeltaEvent v(int v) => this(v: v);

  @override
  MessageDeltaEvent runId(String runId) => this(runId: runId);

  @override
  MessageDeltaEvent seq(int seq) => this(seq: seq);

  @override
  MessageDeltaEvent ts(DateTime ts) => this(ts: ts);

  @override
  MessageDeltaEvent botId(String botId) => this(botId: botId);

  @override
  MessageDeltaEvent type(MessageDeltaEventTypeEnum type) => this(type: type);

  @override
  MessageDeltaEvent payload(MessageDeltaEventPayload payload) =>
      this(payload: payload);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `MessageDeltaEvent(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// MessageDeltaEvent(...).copyWith(id: 12, name: "My name")
  /// ````
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
      v: v == const $CopyWithPlaceholder()
          ? _value.v
          // ignore: cast_nullable_to_non_nullable
          : v as int,
      runId: runId == const $CopyWithPlaceholder()
          ? _value.runId
          // ignore: cast_nullable_to_non_nullable
          : runId as String,
      seq: seq == const $CopyWithPlaceholder()
          ? _value.seq
          // ignore: cast_nullable_to_non_nullable
          : seq as int,
      ts: ts == const $CopyWithPlaceholder()
          ? _value.ts
          // ignore: cast_nullable_to_non_nullable
          : ts as DateTime,
      botId: botId == const $CopyWithPlaceholder()
          ? _value.botId
          // ignore: cast_nullable_to_non_nullable
          : botId as String,
      type: type == const $CopyWithPlaceholder()
          ? _value.type
          // ignore: cast_nullable_to_non_nullable
          : type as MessageDeltaEventTypeEnum,
      payload: payload == const $CopyWithPlaceholder()
          ? _value.payload
          // ignore: cast_nullable_to_non_nullable
          : payload as MessageDeltaEventPayload,
    );
  }
}

extension $MessageDeltaEventCopyWith on MessageDeltaEvent {
  /// Returns a callable class that can be used as follows: `instanceOfMessageDeltaEvent.copyWith(...)` or like so:`instanceOfMessageDeltaEvent.copyWith.fieldName(...)`.
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
