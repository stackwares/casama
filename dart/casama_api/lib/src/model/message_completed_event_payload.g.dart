// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message_completed_event_payload.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$MessageCompletedEventPayloadCWProxy {
  MessageCompletedEventPayload messageId(String messageId);

  MessageCompletedEventPayload content(List<Map<String, Object?>> content);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `MessageCompletedEventPayload(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// MessageCompletedEventPayload(...).copyWith(id: 12, name: "My name")
  /// ```
  MessageCompletedEventPayload call({
    String messageId,
    List<Map<String, Object?>> content,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfMessageCompletedEventPayload.copyWith(...)` or call `instanceOfMessageCompletedEventPayload.copyWith.fieldName(value)` for a single field.
class _$MessageCompletedEventPayloadCWProxyImpl
    implements _$MessageCompletedEventPayloadCWProxy {
  const _$MessageCompletedEventPayloadCWProxyImpl(this._value);

  final MessageCompletedEventPayload _value;

  @override
  MessageCompletedEventPayload messageId(String messageId) =>
      call(messageId: messageId);

  @override
  MessageCompletedEventPayload content(List<Map<String, Object?>> content) =>
      call(content: content);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `MessageCompletedEventPayload(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// MessageCompletedEventPayload(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  MessageCompletedEventPayload call({
    Object? messageId = const $CopyWithPlaceholder(),
    Object? content = const $CopyWithPlaceholder(),
  }) {
    return MessageCompletedEventPayload(
      messageId: messageId == const $CopyWithPlaceholder() || messageId == null
          ? _value.messageId
          // ignore: cast_nullable_to_non_nullable
          : messageId as String,
      content: content == const $CopyWithPlaceholder() || content == null
          ? _value.content
          // ignore: cast_nullable_to_non_nullable
          : content as List<Map<String, Object?>>,
    );
  }
}

extension $MessageCompletedEventPayloadCopyWith
    on MessageCompletedEventPayload {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfMessageCompletedEventPayload.copyWith(...)` or `instanceOfMessageCompletedEventPayload.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$MessageCompletedEventPayloadCWProxy get copyWith =>
      _$MessageCompletedEventPayloadCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MessageCompletedEventPayload _$MessageCompletedEventPayloadFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('MessageCompletedEventPayload', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['message_id', 'content']);
  final val = MessageCompletedEventPayload(
    messageId: $checkedConvert('message_id', (v) => v as String),
    content: $checkedConvert(
      'content',
      (v) =>
          (v as List<dynamic>).map((e) => e as Map<String, dynamic>).toList(),
    ),
  );
  return val;
}, fieldKeyMap: const {'messageId': 'message_id'});

Map<String, dynamic> _$MessageCompletedEventPayloadToJson(
  MessageCompletedEventPayload instance,
) => <String, dynamic>{
  'message_id': instance.messageId,
  'content': instance.content,
};
