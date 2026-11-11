// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bot_share_link.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$BotShareLinkCWProxy {
  BotShareLink token(String token);

  BotShareLink url(String url);

  BotShareLink expiresAt(DateTime? expiresAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `BotShareLink(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// BotShareLink(...).copyWith(id: 12, name: "My name")
  /// ```
  BotShareLink call({String token, String url, DateTime? expiresAt});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfBotShareLink.copyWith(...)` or call `instanceOfBotShareLink.copyWith.fieldName(value)` for a single field.
class _$BotShareLinkCWProxyImpl implements _$BotShareLinkCWProxy {
  const _$BotShareLinkCWProxyImpl(this._value);

  final BotShareLink _value;

  @override
  BotShareLink token(String token) => call(token: token);

  @override
  BotShareLink url(String url) => call(url: url);

  @override
  BotShareLink expiresAt(DateTime? expiresAt) => call(expiresAt: expiresAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `BotShareLink(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// BotShareLink(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  BotShareLink call({
    Object? token = const $CopyWithPlaceholder(),
    Object? url = const $CopyWithPlaceholder(),
    Object? expiresAt = const $CopyWithPlaceholder(),
  }) {
    return BotShareLink(
      token: token == const $CopyWithPlaceholder() || token == null
          ? _value.token
          // ignore: cast_nullable_to_non_nullable
          : token as String,
      url: url == const $CopyWithPlaceholder() || url == null
          ? _value.url
          // ignore: cast_nullable_to_non_nullable
          : url as String,
      expiresAt: expiresAt == const $CopyWithPlaceholder()
          ? _value.expiresAt
          // ignore: cast_nullable_to_non_nullable
          : expiresAt as DateTime?,
    );
  }
}

extension $BotShareLinkCopyWith on BotShareLink {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfBotShareLink.copyWith(...)` or `instanceOfBotShareLink.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$BotShareLinkCWProxy get copyWith => _$BotShareLinkCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BotShareLink _$BotShareLinkFromJson(Map<String, dynamic> json) =>
    $checkedCreate('BotShareLink', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['token', 'url', 'expires_at']);
      final val = BotShareLink(
        token: $checkedConvert('token', (v) => v as String),
        url: $checkedConvert('url', (v) => v as String),
        expiresAt: $checkedConvert(
          'expires_at',
          (v) => v == null ? null : DateTime.parse(v as String),
        ),
      );
      return val;
    }, fieldKeyMap: const {'expiresAt': 'expires_at'});

Map<String, dynamic> _$BotShareLinkToJson(BotShareLink instance) =>
    <String, dynamic>{
      'token': instance.token,
      'url': instance.url,
      'expires_at': instance.expiresAt?.toIso8601String(),
    };
