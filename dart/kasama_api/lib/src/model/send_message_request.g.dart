// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'send_message_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SendMessageRequestCWProxy {
  SendMessageRequest text(String text);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `SendMessageRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// SendMessageRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  SendMessageRequest call({String text});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfSendMessageRequest.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfSendMessageRequest.copyWith.fieldName(...)`
class _$SendMessageRequestCWProxyImpl implements _$SendMessageRequestCWProxy {
  const _$SendMessageRequestCWProxyImpl(this._value);

  final SendMessageRequest _value;

  @override
  SendMessageRequest text(String text) => this(text: text);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `SendMessageRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// SendMessageRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  SendMessageRequest call({Object? text = const $CopyWithPlaceholder()}) {
    return SendMessageRequest(
      text: text == const $CopyWithPlaceholder()
          ? _value.text
          // ignore: cast_nullable_to_non_nullable
          : text as String,
    );
  }
}

extension $SendMessageRequestCopyWith on SendMessageRequest {
  /// Returns a callable class that can be used as follows: `instanceOfSendMessageRequest.copyWith(...)` or like so:`instanceOfSendMessageRequest.copyWith.fieldName(...)`.
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
