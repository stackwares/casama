// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_gpt_sign_in_start.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ChatGptSignInStartCWProxy {
  ChatGptSignInStart authorizeUrl(String authorizeUrl);

  ChatGptSignInStart redirectUri(String redirectUri);

  ChatGptSignInStart state(String state);

  ChatGptSignInStart expiresAt(DateTime expiresAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ChatGptSignInStart(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ChatGptSignInStart(...).copyWith(id: 12, name: "My name")
  /// ```
  ChatGptSignInStart call({
    String authorizeUrl,
    String redirectUri,
    String state,
    DateTime expiresAt,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfChatGptSignInStart.copyWith(...)` or call `instanceOfChatGptSignInStart.copyWith.fieldName(value)` for a single field.
class _$ChatGptSignInStartCWProxyImpl implements _$ChatGptSignInStartCWProxy {
  const _$ChatGptSignInStartCWProxyImpl(this._value);

  final ChatGptSignInStart _value;

  @override
  ChatGptSignInStart authorizeUrl(String authorizeUrl) =>
      call(authorizeUrl: authorizeUrl);

  @override
  ChatGptSignInStart redirectUri(String redirectUri) =>
      call(redirectUri: redirectUri);

  @override
  ChatGptSignInStart state(String state) => call(state: state);

  @override
  ChatGptSignInStart expiresAt(DateTime expiresAt) =>
      call(expiresAt: expiresAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ChatGptSignInStart(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ChatGptSignInStart(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ChatGptSignInStart call({
    Object? authorizeUrl = const $CopyWithPlaceholder(),
    Object? redirectUri = const $CopyWithPlaceholder(),
    Object? state = const $CopyWithPlaceholder(),
    Object? expiresAt = const $CopyWithPlaceholder(),
  }) {
    return ChatGptSignInStart(
      authorizeUrl:
          authorizeUrl == const $CopyWithPlaceholder() || authorizeUrl == null
          ? _value.authorizeUrl
          // ignore: cast_nullable_to_non_nullable
          : authorizeUrl as String,
      redirectUri:
          redirectUri == const $CopyWithPlaceholder() || redirectUri == null
          ? _value.redirectUri
          // ignore: cast_nullable_to_non_nullable
          : redirectUri as String,
      state: state == const $CopyWithPlaceholder() || state == null
          ? _value.state
          // ignore: cast_nullable_to_non_nullable
          : state as String,
      expiresAt: expiresAt == const $CopyWithPlaceholder() || expiresAt == null
          ? _value.expiresAt
          // ignore: cast_nullable_to_non_nullable
          : expiresAt as DateTime,
    );
  }
}

extension $ChatGptSignInStartCopyWith on ChatGptSignInStart {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfChatGptSignInStart.copyWith(...)` or `instanceOfChatGptSignInStart.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ChatGptSignInStartCWProxy get copyWith =>
      _$ChatGptSignInStartCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChatGptSignInStart _$ChatGptSignInStartFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'ChatGptSignInStart',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'authorize_url',
            'redirect_uri',
            'state',
            'expires_at',
          ],
        );
        final val = ChatGptSignInStart(
          authorizeUrl: $checkedConvert('authorize_url', (v) => v as String),
          redirectUri: $checkedConvert('redirect_uri', (v) => v as String),
          state: $checkedConvert('state', (v) => v as String),
          expiresAt: $checkedConvert(
            'expires_at',
            (v) => DateTime.parse(v as String),
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'authorizeUrl': 'authorize_url',
        'redirectUri': 'redirect_uri',
        'expiresAt': 'expires_at',
      },
    );

Map<String, dynamic> _$ChatGptSignInStartToJson(ChatGptSignInStart instance) =>
    <String, dynamic>{
      'authorize_url': instance.authorizeUrl,
      'redirect_uri': instance.redirectUri,
      'state': instance.state,
      'expires_at': instance.expiresAt.toIso8601String(),
    };
