// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message_delta_event_payload.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$MessageDeltaEventPayloadCWProxy {
  MessageDeltaEventPayload messageId(String messageId);

  MessageDeltaEventPayload text(String text);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `MessageDeltaEventPayload(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// MessageDeltaEventPayload(...).copyWith(id: 12, name: "My name")
  /// ```
  MessageDeltaEventPayload call({String messageId, String text});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfMessageDeltaEventPayload.copyWith(...)` or call `instanceOfMessageDeltaEventPayload.copyWith.fieldName(value)` for a single field.
class _$MessageDeltaEventPayloadCWProxyImpl
    implements _$MessageDeltaEventPayloadCWProxy {
  const _$MessageDeltaEventPayloadCWProxyImpl(this._value);

  final MessageDeltaEventPayload _value;

  @override
  MessageDeltaEventPayload messageId(String messageId) =>
      call(messageId: messageId);

  @override
  MessageDeltaEventPayload text(String text) => call(text: text);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `MessageDeltaEventPayload(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// MessageDeltaEventPayload(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  MessageDeltaEventPayload call({
    Object? messageId = const $CopyWithPlaceholder(),
    Object? text = const $CopyWithPlaceholder(),
  }) {
    return MessageDeltaEventPayload(
      messageId: messageId == const $CopyWithPlaceholder() || messageId == null
          ? _value.messageId
          // ignore: cast_nullable_to_non_nullable
          : messageId as String,
      text: text == const $CopyWithPlaceholder() || text == null
          ? _value.text
          // ignore: cast_nullable_to_non_nullable
          : text as String,
    );
  }
}

extension $MessageDeltaEventPayloadCopyWith on MessageDeltaEventPayload {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfMessageDeltaEventPayload.copyWith(...)` or `instanceOfMessageDeltaEventPayload.copyWith.fieldName(...)`.
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
