// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'place_list.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PlaceListCWProxy {
  PlaceList items(List<Place> items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PlaceList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PlaceList(...).copyWith(id: 12, name: "My name")
  /// ```
  PlaceList call({List<Place> items});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfPlaceList.copyWith(...)` or call `instanceOfPlaceList.copyWith.fieldName(value)` for a single field.
class _$PlaceListCWProxyImpl implements _$PlaceListCWProxy {
  const _$PlaceListCWProxyImpl(this._value);

  final PlaceList _value;

  @override
  PlaceList items(List<Place> items) => call(items: items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PlaceList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PlaceList(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  PlaceList call({Object? items = const $CopyWithPlaceholder()}) {
    return PlaceList(
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<Place>,
    );
  }
}

extension $PlaceListCopyWith on PlaceList {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfPlaceList.copyWith(...)` or `instanceOfPlaceList.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PlaceListCWProxy get copyWith => _$PlaceListCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlaceList _$PlaceListFromJson(Map<String, dynamic> json) =>
    $checkedCreate('PlaceList', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items']);
      final val = PlaceList(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => Place.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$PlaceListToJson(PlaceList instance) => <String, dynamic>{
  'items': instance.items.map((e) => e.toJson()).toList(),
};
