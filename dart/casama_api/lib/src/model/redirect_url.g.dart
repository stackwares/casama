// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'redirect_url.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$RedirectUrlCWProxy {
  RedirectUrl url(String url);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `RedirectUrl(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// RedirectUrl(...).copyWith(id: 12, name: "My name")
  /// ```
  RedirectUrl call({String url});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfRedirectUrl.copyWith(...)` or call `instanceOfRedirectUrl.copyWith.fieldName(value)` for a single field.
class _$RedirectUrlCWProxyImpl implements _$RedirectUrlCWProxy {
  const _$RedirectUrlCWProxyImpl(this._value);

  final RedirectUrl _value;

  @override
  RedirectUrl url(String url) => call(url: url);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `RedirectUrl(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// RedirectUrl(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  RedirectUrl call({Object? url = const $CopyWithPlaceholder()}) {
    return RedirectUrl(
      url: url == const $CopyWithPlaceholder() || url == null
          ? _value.url
          // ignore: cast_nullable_to_non_nullable
          : url as String,
    );
  }
}

extension $RedirectUrlCopyWith on RedirectUrl {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfRedirectUrl.copyWith(...)` or `instanceOfRedirectUrl.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$RedirectUrlCWProxy get copyWith => _$RedirectUrlCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RedirectUrl _$RedirectUrlFromJson(Map<String, dynamic> json) =>
    $checkedCreate('RedirectUrl', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['url']);
      final val = RedirectUrl(url: $checkedConvert('url', (v) => v as String));
      return val;
    });

Map<String, dynamic> _$RedirectUrlToJson(RedirectUrl instance) =>
    <String, dynamic>{'url': instance.url};
