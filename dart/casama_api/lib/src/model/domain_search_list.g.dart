// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'domain_search_list.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$DomainSearchListCWProxy {
  DomainSearchList query(String query);

  DomainSearchList items(List<DomainSearchResult> items);

  DomainSearchList tlds(List<String> tlds);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DomainSearchList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DomainSearchList(...).copyWith(id: 12, name: "My name")
  /// ```
  DomainSearchList call({
    String query,
    List<DomainSearchResult> items,
    List<String> tlds,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfDomainSearchList.copyWith(...)` or call `instanceOfDomainSearchList.copyWith.fieldName(value)` for a single field.
class _$DomainSearchListCWProxyImpl implements _$DomainSearchListCWProxy {
  const _$DomainSearchListCWProxyImpl(this._value);

  final DomainSearchList _value;

  @override
  DomainSearchList query(String query) => call(query: query);

  @override
  DomainSearchList items(List<DomainSearchResult> items) => call(items: items);

  @override
  DomainSearchList tlds(List<String> tlds) => call(tlds: tlds);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DomainSearchList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DomainSearchList(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  DomainSearchList call({
    Object? query = const $CopyWithPlaceholder(),
    Object? items = const $CopyWithPlaceholder(),
    Object? tlds = const $CopyWithPlaceholder(),
  }) {
    return DomainSearchList(
      query: query == const $CopyWithPlaceholder() || query == null
          ? _value.query
          // ignore: cast_nullable_to_non_nullable
          : query as String,
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<DomainSearchResult>,
      tlds: tlds == const $CopyWithPlaceholder() || tlds == null
          ? _value.tlds
          // ignore: cast_nullable_to_non_nullable
          : tlds as List<String>,
    );
  }
}

extension $DomainSearchListCopyWith on DomainSearchList {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfDomainSearchList.copyWith(...)` or `instanceOfDomainSearchList.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$DomainSearchListCWProxy get copyWith => _$DomainSearchListCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DomainSearchList _$DomainSearchListFromJson(Map<String, dynamic> json) =>
    $checkedCreate('DomainSearchList', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['query', 'items', 'tlds']);
      final val = DomainSearchList(
        query: $checkedConvert('query', (v) => v as String),
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map(
                (e) => DomainSearchResult.fromJson(e as Map<String, dynamic>),
              )
              .toList(),
        ),
        tlds: $checkedConvert(
          'tlds',
          (v) => (v as List<dynamic>).map((e) => e as String).toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$DomainSearchListToJson(DomainSearchList instance) =>
    <String, dynamic>{
      'query': instance.query,
      'items': instance.items.map((e) => e.toJson()).toList(),
      'tlds': instance.tlds,
    };
