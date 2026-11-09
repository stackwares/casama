// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message_completed_event_payload.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$MessageCompletedEventPayloadCWProxy {
  MessageCompletedEventPayload messageId(String messageId);

  MessageCompletedEventPayload content(List<Map<String, Object?>> content);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `MessageCompletedEventPayload(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// MessageCompletedEventPayload(...).copyWith(id: 12, name: "My name")
  /// ````
  MessageCompletedEventPayload call({
    String messageId,
    List<Map<String, Object?>> content,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfMessageCompletedEventPayload.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfMessageCompletedEventPayload.copyWith.fieldName(...)`
class _$MessageCompletedEventPayloadCWProxyImpl
    implements _$MessageCompletedEventPayloadCWProxy {
  const _$MessageCompletedEventPayloadCWProxyImpl(this._value);

  final MessageCompletedEventPayload _value;

  @override
  MessageCompletedEventPayload messageId(String messageId) =>
      this(messageId: messageId);

  @override
  MessageCompletedEventPayload content(List<Map<String, Object?>> content) =>
      this(content: content);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `MessageCompletedEventPayload(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// MessageCompletedEventPayload(...).copyWith(id: 12, name: "My name")
  /// ````
  MessageCompletedEventPayload call({
    Object? messageId = const $CopyWithPlaceholder(),
    Object? content = const $CopyWithPlaceholder(),
  }) {
    return MessageCompletedEventPayload(
      messageId: messageId == const $CopyWithPlaceholder()
          ? _value.messageId
          // ignore: cast_nullable_to_non_nullable
          : messageId as String,
      content: content == const $CopyWithPlaceholder()
          ? _value.content
          // ignore: cast_nullable_to_non_nullable
          : content as List<Map<String, Object?>>,
    );
  }
}

extension $MessageCompletedEventPayloadCopyWith
    on MessageCompletedEventPayload {
  /// Returns a callable class that can be used as follows: `instanceOfMessageCompletedEventPayload.copyWith(...)` or like so:`instanceOfMessageCompletedEventPayload.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$MessageCompletedEventPayloadCWProxy get copyWith =>
      _$MessageCompletedEventPayloadCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MessageCompletedEventPayload _$MessageCompletedEventPayloadFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'MessageCompletedEventPayload',
  json,
  ($checkedConvert) {
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
  },
  fieldKeyMap: const {'messageId': 'message_id'},
);

Map<String, dynamic> _$MessageCompletedEventPayloadToJson(
  MessageCompletedEventPayload instance,
) => <String, dynamic>{
  'message_id': instance.messageId,
  'content': instance.content,
};
