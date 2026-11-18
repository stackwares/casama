// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pack_list.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PackListCWProxy {
  PackList items(List<Pack> items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PackList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PackList(...).copyWith(id: 12, name: "My name")
  /// ```
  PackList call({List<Pack> items});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfPackList.copyWith(...)` or call `instanceOfPackList.copyWith.fieldName(value)` for a single field.
class _$PackListCWProxyImpl implements _$PackListCWProxy {
  const _$PackListCWProxyImpl(this._value);

  final PackList _value;

  @override
  PackList items(List<Pack> items) => call(items: items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PackList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PackList(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  PackList call({Object? items = const $CopyWithPlaceholder()}) {
    return PackList(
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<Pack>,
    );
  }
}

extension $PackListCopyWith on PackList {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfPackList.copyWith(...)` or `instanceOfPackList.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PackListCWProxy get copyWith => _$PackListCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PackList _$PackListFromJson(Map<String, dynamic> json) =>
    $checkedCreate('PackList', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items']);
      final val = PackList(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => Pack.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$PackListToJson(PackList instance) => <String, dynamic>{
  'items': instance.items.map((e) => e.toJson()).toList(),
};
