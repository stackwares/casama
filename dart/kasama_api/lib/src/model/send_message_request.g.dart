// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'send_message_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SendMessageRequestCWProxy {
  SendMessageRequest text(String text);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SendMessageRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SendMessageRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  SendMessageRequest call({String text});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfSendMessageRequest.copyWith(...)` or call `instanceOfSendMessageRequest.copyWith.fieldName(value)` for a single field.
class _$SendMessageRequestCWProxyImpl implements _$SendMessageRequestCWProxy {
  const _$SendMessageRequestCWProxyImpl(this._value);

  final SendMessageRequest _value;

  @override
  SendMessageRequest text(String text) => call(text: text);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SendMessageRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SendMessageRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  SendMessageRequest call({Object? text = const $CopyWithPlaceholder()}) {
    return SendMessageRequest(
      text: text == const $CopyWithPlaceholder() || text == null
          ? _value.text
          // ignore: cast_nullable_to_non_nullable
          : text as String,
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

SendMessageRequest _$SendMessageRequestFromJson(Map<String, dynamic> json) =>
    $checkedCreate('SendMessageRequest', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['text']);
      final val = SendMessageRequest(
        text: $checkedConvert('text', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$SendMessageRequestToJson(SendMessageRequest instance) =>
    <String, dynamic>{'text': instance.text};
