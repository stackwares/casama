// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_gpt_sign_in_complete_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ChatGptSignInCompleteRequestCWProxy {
  ChatGptSignInCompleteRequest state(String state);

  ChatGptSignInCompleteRequest code(String? code);

  ChatGptSignInCompleteRequest clientId(String? clientId);

  ChatGptSignInCompleteRequest error(String? error);

  ChatGptSignInCompleteRequest errorDescription(String? errorDescription);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ChatGptSignInCompleteRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ChatGptSignInCompleteRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  ChatGptSignInCompleteRequest call({
    String state,
    String? code,
    String? clientId,
    String? error,
    String? errorDescription,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfChatGptSignInCompleteRequest.copyWith(...)` or call `instanceOfChatGptSignInCompleteRequest.copyWith.fieldName(value)` for a single field.
class _$ChatGptSignInCompleteRequestCWProxyImpl
    implements _$ChatGptSignInCompleteRequestCWProxy {
  const _$ChatGptSignInCompleteRequestCWProxyImpl(this._value);

  final ChatGptSignInCompleteRequest _value;

  @override
  ChatGptSignInCompleteRequest state(String state) => call(state: state);

  @override
  ChatGptSignInCompleteRequest code(String? code) => call(code: code);

  @override
  ChatGptSignInCompleteRequest clientId(String? clientId) =>
      call(clientId: clientId);

  @override
  ChatGptSignInCompleteRequest error(String? error) => call(error: error);

  @override
  ChatGptSignInCompleteRequest errorDescription(String? errorDescription) =>
      call(errorDescription: errorDescription);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ChatGptSignInCompleteRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ChatGptSignInCompleteRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ChatGptSignInCompleteRequest call({
    Object? state = const $CopyWithPlaceholder(),
    Object? code = const $CopyWithPlaceholder(),
    Object? clientId = const $CopyWithPlaceholder(),
    Object? error = const $CopyWithPlaceholder(),
    Object? errorDescription = const $CopyWithPlaceholder(),
  }) {
    return ChatGptSignInCompleteRequest(
      state: state == const $CopyWithPlaceholder() || state == null
          ? _value.state
          // ignore: cast_nullable_to_non_nullable
          : state as String,
      code: code == const $CopyWithPlaceholder()
          ? _value.code
          // ignore: cast_nullable_to_non_nullable
          : code as String?,
      clientId: clientId == const $CopyWithPlaceholder()
          ? _value.clientId
          // ignore: cast_nullable_to_non_nullable
          : clientId as String?,
      error: error == const $CopyWithPlaceholder()
          ? _value.error
          // ignore: cast_nullable_to_non_nullable
          : error as String?,
      errorDescription: errorDescription == const $CopyWithPlaceholder()
          ? _value.errorDescription
          // ignore: cast_nullable_to_non_nullable
          : errorDescription as String?,
    );
  }
}

extension $ChatGptSignInCompleteRequestCopyWith
    on ChatGptSignInCompleteRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfChatGptSignInCompleteRequest.copyWith(...)` or `instanceOfChatGptSignInCompleteRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ChatGptSignInCompleteRequestCWProxy get copyWith =>
      _$ChatGptSignInCompleteRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChatGptSignInCompleteRequest _$ChatGptSignInCompleteRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'ChatGptSignInCompleteRequest',
  json,
  ($checkedConvert) {
    $checkKeys(json, requiredKeys: const ['state']);
    final val = ChatGptSignInCompleteRequest(
      state: $checkedConvert('state', (v) => v as String),
      code: $checkedConvert('code', (v) => v as String?),
      clientId: $checkedConvert('client_id', (v) => v as String?),
      error: $checkedConvert('error', (v) => v as String?),
      errorDescription: $checkedConvert(
        'error_description',
        (v) => v as String?,
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'clientId': 'client_id',
    'errorDescription': 'error_description',
  },
);

Map<String, dynamic> _$ChatGptSignInCompleteRequestToJson(
  ChatGptSignInCompleteRequest instance,
) => <String, dynamic>{
  'state': instance.state,
  'code': ?instance.code,
  'client_id': ?instance.clientId,
  'error': ?instance.error,
  'error_description': ?instance.errorDescription,
};
