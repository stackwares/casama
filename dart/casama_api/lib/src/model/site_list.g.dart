// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'site_list.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SiteListCWProxy {
  SiteList items(List<Site> items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SiteList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SiteList(...).copyWith(id: 12, name: "My name")
  /// ```
  SiteList call({List<Site> items});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfSiteList.copyWith(...)` or call `instanceOfSiteList.copyWith.fieldName(value)` for a single field.
class _$SiteListCWProxyImpl implements _$SiteListCWProxy {
  const _$SiteListCWProxyImpl(this._value);

  final SiteList _value;

  @override
  SiteList items(List<Site> items) => call(items: items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SiteList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SiteList(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  SiteList call({Object? items = const $CopyWithPlaceholder()}) {
    return SiteList(
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<Site>,
    );
  }
}

extension $SiteListCopyWith on SiteList {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfSiteList.copyWith(...)` or `instanceOfSiteList.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SiteListCWProxy get copyWith => _$SiteListCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SiteList _$SiteListFromJson(Map<String, dynamic> json) =>
    $checkedCreate('SiteList', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items']);
      final val = SiteList(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => Site.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$SiteListToJson(SiteList instance) => <String, dynamic>{
  'items': instance.items.map((e) => e.toJson()).toList(),
};
