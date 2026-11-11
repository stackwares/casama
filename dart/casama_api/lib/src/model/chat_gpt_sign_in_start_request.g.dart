// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_gpt_sign_in_start_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ChatGptSignInStartRequestCWProxy {
  ChatGptSignInStartRequest orgId(String orgId);

  ChatGptSignInStartRequest redirectPort(int redirectPort);

  ChatGptSignInStartRequest credentialId(String? credentialId);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ChatGptSignInStartRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ChatGptSignInStartRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  ChatGptSignInStartRequest call({
    String orgId,
    int redirectPort,
    String? credentialId,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfChatGptSignInStartRequest.copyWith(...)` or call `instanceOfChatGptSignInStartRequest.copyWith.fieldName(value)` for a single field.
class _$ChatGptSignInStartRequestCWProxyImpl
    implements _$ChatGptSignInStartRequestCWProxy {
  const _$ChatGptSignInStartRequestCWProxyImpl(this._value);

  final ChatGptSignInStartRequest _value;

  @override
  ChatGptSignInStartRequest orgId(String orgId) => call(orgId: orgId);

  @override
  ChatGptSignInStartRequest redirectPort(int redirectPort) =>
      call(redirectPort: redirectPort);

  @override
  ChatGptSignInStartRequest credentialId(String? credentialId) =>
      call(credentialId: credentialId);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ChatGptSignInStartRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ChatGptSignInStartRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ChatGptSignInStartRequest call({
    Object? orgId = const $CopyWithPlaceholder(),
    Object? redirectPort = const $CopyWithPlaceholder(),
    Object? credentialId = const $CopyWithPlaceholder(),
  }) {
    return ChatGptSignInStartRequest(
      orgId: orgId == const $CopyWithPlaceholder() || orgId == null
          ? _value.orgId
          // ignore: cast_nullable_to_non_nullable
          : orgId as String,
      redirectPort:
          redirectPort == const $CopyWithPlaceholder() || redirectPort == null
          ? _value.redirectPort
          // ignore: cast_nullable_to_non_nullable
          : redirectPort as int,
      credentialId: credentialId == const $CopyWithPlaceholder()
          ? _value.credentialId
          // ignore: cast_nullable_to_non_nullable
          : credentialId as String?,
    );
  }
}

extension $ChatGptSignInStartRequestCopyWith on ChatGptSignInStartRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfChatGptSignInStartRequest.copyWith(...)` or `instanceOfChatGptSignInStartRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ChatGptSignInStartRequestCWProxy get copyWith =>
      _$ChatGptSignInStartRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChatGptSignInStartRequest _$ChatGptSignInStartRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'ChatGptSignInStartRequest',
  json,
  ($checkedConvert) {
    $checkKeys(json, requiredKeys: const ['org_id', 'redirect_port']);
    final val = ChatGptSignInStartRequest(
      orgId: $checkedConvert('org_id', (v) => v as String),
      redirectPort: $checkedConvert('redirect_port', (v) => (v as num).toInt()),
      credentialId: $checkedConvert('credential_id', (v) => v as String?),
    );
    return val;
  },
  fieldKeyMap: const {
    'orgId': 'org_id',
    'redirectPort': 'redirect_port',
    'credentialId': 'credential_id',
  },
);

Map<String, dynamic> _$ChatGptSignInStartRequestToJson(
  ChatGptSignInStartRequest instance,
) => <String, dynamic>{
  'org_id': instance.orgId,
  'redirect_port': instance.redirectPort,
  'credential_id': ?instance.credentialId,
};
