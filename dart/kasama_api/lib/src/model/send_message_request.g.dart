// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'send_message_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SendMessageRequestCWProxy {
  SendMessageRequest text(String? text);

  SendMessageRequest attachments(List<MessageAttachment>? attachments);

  SendMessageRequest uiAction(UiActionPart? uiAction);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SendMessageRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SendMessageRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  SendMessageRequest call({
    String? text,
    List<MessageAttachment>? attachments,
    UiActionPart? uiAction,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfSendMessageRequest.copyWith(...)` or call `instanceOfSendMessageRequest.copyWith.fieldName(value)` for a single field.
class _$SendMessageRequestCWProxyImpl implements _$SendMessageRequestCWProxy {
  const _$SendMessageRequestCWProxyImpl(this._value);

  final SendMessageRequest _value;

  @override
  SendMessageRequest text(String? text) => call(text: text);

  @override
  SendMessageRequest attachments(List<MessageAttachment>? attachments) =>
      call(attachments: attachments);

  @override
  SendMessageRequest uiAction(UiActionPart? uiAction) =>
      call(uiAction: uiAction);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SendMessageRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SendMessageRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  SendMessageRequest call({
    Object? text = const $CopyWithPlaceholder(),
    Object? attachments = const $CopyWithPlaceholder(),
    Object? uiAction = const $CopyWithPlaceholder(),
  }) {
    return SendMessageRequest(
      text: text == const $CopyWithPlaceholder()
          ? _value.text
          // ignore: cast_nullable_to_non_nullable
          : text as String?,
      attachments: attachments == const $CopyWithPlaceholder()
          ? _value.attachments
          // ignore: cast_nullable_to_non_nullable
          : attachments as List<MessageAttachment>?,
      uiAction: uiAction == const $CopyWithPlaceholder()
          ? _value.uiAction
          // ignore: cast_nullable_to_non_nullable
          : uiAction as UiActionPart?,
    );
  }
}

extension $SendMessageRequestCopyWith on SendMessageRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfSendMessageRequest.copyWith(...)` or `instanceOfSendMessageRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SendMessageRequestCWProxy get copyWith =>
      _$SendMessageRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SendMessageRequest _$SendMessageRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('SendMessageRequest', json, ($checkedConvert) {
  final val = SendMessageRequest(
    text: $checkedConvert('text', (v) => v as String? ?? ''),
    attachments: $checkedConvert(
      'attachments',
      (v) => (v as List<dynamic>?)
          ?.map((e) => MessageAttachment.fromJson(e as Map<String, dynamic>))
          .toList(),
    ),
    uiAction: $checkedConvert(
      'ui_action',
      (v) =>
          v == null ? null : UiActionPart.fromJson(v as Map<String, dynamic>),
    ),
  );
  return val;
}, fieldKeyMap: const {'uiAction': 'ui_action'});

Map<String, dynamic> _$SendMessageRequestToJson(SendMessageRequest instance) =>
    <String, dynamic>{
      'text': ?instance.text,
      'attachments': ?instance.attachments?.map((e) => e.toJson()).toList(),
      'ui_action': ?instance.uiAction?.toJson(),
    };
