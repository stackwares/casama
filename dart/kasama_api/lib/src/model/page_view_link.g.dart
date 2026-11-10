// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'page_view_link.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PageViewLinkCWProxy {
  PageViewLink url(String url);

  PageViewLink expiresAt(DateTime expiresAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PageViewLink(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PageViewLink(...).copyWith(id: 12, name: "My name")
  /// ```
  PageViewLink call({String url, DateTime expiresAt});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfPageViewLink.copyWith(...)` or call `instanceOfPageViewLink.copyWith.fieldName(value)` for a single field.
class _$PageViewLinkCWProxyImpl implements _$PageViewLinkCWProxy {
  const _$PageViewLinkCWProxyImpl(this._value);

  final PageViewLink _value;

  @override
  PageViewLink url(String url) => call(url: url);

  @override
  PageViewLink expiresAt(DateTime expiresAt) => call(expiresAt: expiresAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PageViewLink(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PageViewLink(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  PageViewLink call({
    Object? url = const $CopyWithPlaceholder(),
    Object? expiresAt = const $CopyWithPlaceholder(),
  }) {
    return PageViewLink(
      url: url == const $CopyWithPlaceholder() || url == null
          ? _value.url
          // ignore: cast_nullable_to_non_nullable
          : url as String,
      expiresAt: expiresAt == const $CopyWithPlaceholder() || expiresAt == null
          ? _value.expiresAt
          // ignore: cast_nullable_to_non_nullable
          : expiresAt as DateTime,
    );
  }
}

extension $PageViewLinkCopyWith on PageViewLink {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfPageViewLink.copyWith(...)` or `instanceOfPageViewLink.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PageViewLinkCWProxy get copyWith => _$PageViewLinkCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PageViewLink _$PageViewLinkFromJson(Map<String, dynamic> json) =>
    $checkedCreate('PageViewLink', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['url', 'expires_at']);
      final val = PageViewLink(
        url: $checkedConvert('url', (v) => v as String),
        expiresAt: $checkedConvert(
          'expires_at',
          (v) => DateTime.parse(v as String),
        ),
      );
      return val;
    }, fieldKeyMap: const {'expiresAt': 'expires_at'});

Map<String, dynamic> _$PageViewLinkToJson(PageViewLink instance) =>
    <String, dynamic>{
      'url': instance.url,
      'expires_at': instance.expiresAt.toIso8601String(),
    };
