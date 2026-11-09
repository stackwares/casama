// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message_delta_event_payload.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$MessageDeltaEventPayloadCWProxy {
  MessageDeltaEventPayload messageId(String messageId);

  MessageDeltaEventPayload text(String text);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `MessageDeltaEventPayload(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// MessageDeltaEventPayload(...).copyWith(id: 12, name: "My name")
  /// ````
  MessageDeltaEventPayload call({String messageId, String text});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfMessageDeltaEventPayload.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfMessageDeltaEventPayload.copyWith.fieldName(...)`
class _$MessageDeltaEventPayloadCWProxyImpl
    implements _$MessageDeltaEventPayloadCWProxy {
  const _$MessageDeltaEventPayloadCWProxyImpl(this._value);

  final MessageDeltaEventPayload _value;

  @override
  MessageDeltaEventPayload messageId(String messageId) =>
      this(messageId: messageId);

  @override
  MessageDeltaEventPayload text(String text) => this(text: text);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `MessageDeltaEventPayload(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// MessageDeltaEventPayload(...).copyWith(id: 12, name: "My name")
  /// ````
  MessageDeltaEventPayload call({
    Object? messageId = const $CopyWithPlaceholder(),
    Object? text = const $CopyWithPlaceholder(),
  }) {
    return MessageDeltaEventPayload(
      messageId: messageId == const $CopyWithPlaceholder()
          ? _value.messageId
          // ignore: cast_nullable_to_non_nullable
          : messageId as String,
      text: text == const $CopyWithPlaceholder()
          ? _value.text
          // ignore: cast_nullable_to_non_nullable
          : text as String,
    );
  }
}

extension $MessageDeltaEventPayloadCopyWith on MessageDeltaEventPayload {
  /// Returns a callable class that can be used as follows: `instanceOfMessageDeltaEventPayload.copyWith(...)` or like so:`instanceOfMessageDeltaEventPayload.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$MessageDeltaEventPayloadCWProxy get copyWith =>
      _$MessageDeltaEventPayloadCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MessageDeltaEventPayload _$MessageDeltaEventPayloadFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('MessageDeltaEventPayload', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['message_id', 'text']);
  final val = MessageDeltaEventPayload(
    messageId: $checkedConvert('message_id', (v) => v as String),
    text: $checkedConvert('text', (v) => v as String),
  );
  return val;
}, fieldKeyMap: const {'messageId': 'message_id'});

Map<String, dynamic> _$MessageDeltaEventPayloadToJson(
  MessageDeltaEventPayload instance,
) => <String, dynamic>{'message_id': instance.messageId, 'text': instance.text};
