// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message_completed_event.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$MessageCompletedEventCWProxy {
  MessageCompletedEvent v(int v);

  MessageCompletedEvent runId(String runId);

  MessageCompletedEvent seq(int seq);

  MessageCompletedEvent ts(DateTime ts);

  MessageCompletedEvent botId(String botId);

  MessageCompletedEvent type(MessageCompletedEventTypeEnum type);

  MessageCompletedEvent payload(MessageCompletedEventPayload payload);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `MessageCompletedEvent(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// MessageCompletedEvent(...).copyWith(id: 12, name: "My name")
  /// ````
  MessageCompletedEvent call({
    int v,
    String runId,
    int seq,
    DateTime ts,
    String botId,
    MessageCompletedEventTypeEnum type,
    MessageCompletedEventPayload payload,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfMessageCompletedEvent.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfMessageCompletedEvent.copyWith.fieldName(...)`
class _$MessageCompletedEventCWProxyImpl
    implements _$MessageCompletedEventCWProxy {
  const _$MessageCompletedEventCWProxyImpl(this._value);

  final MessageCompletedEvent _value;

  @override
  MessageCompletedEvent v(int v) => this(v: v);

  @override
  MessageCompletedEvent runId(String runId) => this(runId: runId);

  @override
  MessageCompletedEvent seq(int seq) => this(seq: seq);

  @override
  MessageCompletedEvent ts(DateTime ts) => this(ts: ts);

  @override
  MessageCompletedEvent botId(String botId) => this(botId: botId);

  @override
  MessageCompletedEvent type(MessageCompletedEventTypeEnum type) =>
      this(type: type);

  @override
  MessageCompletedEvent payload(MessageCompletedEventPayload payload) =>
      this(payload: payload);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `MessageCompletedEvent(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// MessageCompletedEvent(...).copyWith(id: 12, name: "My name")
  /// ````
  MessageCompletedEvent call({
    Object? v = const $CopyWithPlaceholder(),
    Object? runId = const $CopyWithPlaceholder(),
    Object? seq = const $CopyWithPlaceholder(),
    Object? ts = const $CopyWithPlaceholder(),
    Object? botId = const $CopyWithPlaceholder(),
    Object? type = const $CopyWithPlaceholder(),
    Object? payload = const $CopyWithPlaceholder(),
  }) {
    return MessageCompletedEvent(
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
          : type as MessageCompletedEventTypeEnum,
      payload: payload == const $CopyWithPlaceholder()
          ? _value.payload
          // ignore: cast_nullable_to_non_nullable
          : payload as MessageCompletedEventPayload,
    );
  }
}

extension $MessageCompletedEventCopyWith on MessageCompletedEvent {
  /// Returns a callable class that can be used as follows: `instanceOfMessageCompletedEvent.copyWith(...)` or like so:`instanceOfMessageCompletedEvent.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$MessageCompletedEventCWProxy get copyWith =>
      _$MessageCompletedEventCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MessageCompletedEvent _$MessageCompletedEventFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'MessageCompletedEvent',
  json,
  ($checkedConvert) {
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
    final val = MessageCompletedEvent(
      v: $checkedConvert('v', (v) => (v as num).toInt()),
      runId: $checkedConvert('run_id', (v) => v as String),
      seq: $checkedConvert('seq', (v) => (v as num).toInt()),
      ts: $checkedConvert('ts', (v) => DateTime.parse(v as String)),
      botId: $checkedConvert('bot_id', (v) => v as String),
      type: $checkedConvert(
        'type',
        (v) => $enumDecode(_$MessageCompletedEventTypeEnumEnumMap, v),
      ),
      payload: $checkedConvert(
        'payload',
        (v) => MessageCompletedEventPayload.fromJson(v as Map<String, dynamic>),
      ),
    );
    return val;
  },
  fieldKeyMap: const {'runId': 'run_id', 'botId': 'bot_id'},
);

Map<String, dynamic> _$MessageCompletedEventToJson(
  MessageCompletedEvent instance,
) => <String, dynamic>{
  'v': instance.v,
  'run_id': instance.runId,
  'seq': instance.seq,
  'ts': instance.ts.toIso8601String(),
  'bot_id': instance.botId,
  'type': _$MessageCompletedEventTypeEnumEnumMap[instance.type]!,
  'payload': instance.payload.toJson(),
};

const _$MessageCompletedEventTypeEnumEnumMap = {
  MessageCompletedEventTypeEnum.messagePeriodCompleted: 'message.completed',
};
