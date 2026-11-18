// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'list_device_places200_response.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ListDevicePlaces200ResponseCWProxy {
  ListDevicePlaces200Response items(List<DevicePlace> items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ListDevicePlaces200Response(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ListDevicePlaces200Response(...).copyWith(id: 12, name: "My name")
  /// ```
  ListDevicePlaces200Response call({List<DevicePlace> items});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfListDevicePlaces200Response.copyWith(...)` or call `instanceOfListDevicePlaces200Response.copyWith.fieldName(value)` for a single field.
class _$ListDevicePlaces200ResponseCWProxyImpl
    implements _$ListDevicePlaces200ResponseCWProxy {
  const _$ListDevicePlaces200ResponseCWProxyImpl(this._value);

  final ListDevicePlaces200Response _value;

  @override
  ListDevicePlaces200Response items(List<DevicePlace> items) =>
      call(items: items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ListDevicePlaces200Response(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ListDevicePlaces200Response(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ListDevicePlaces200Response call({
    Object? items = const $CopyWithPlaceholder(),
  }) {
    return ListDevicePlaces200Response(
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<DevicePlace>,
    );
  }
}

extension $ListDevicePlaces200ResponseCopyWith on ListDevicePlaces200Response {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfListDevicePlaces200Response.copyWith(...)` or `instanceOfListDevicePlaces200Response.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ListDevicePlaces200ResponseCWProxy get copyWith =>
      _$ListDevicePlaces200ResponseCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ListDevicePlaces200Response _$ListDevicePlaces200ResponseFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('ListDevicePlaces200Response', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['items']);
  final val = ListDevicePlaces200Response(
    items: $checkedConvert(
      'items',
      (v) => (v as List<dynamic>)
          .map((e) => DevicePlace.fromJson(e as Map<String, dynamic>))
          .toList(),
    ),
  );
  return val;
});

Map<String, dynamic> _$ListDevicePlaces200ResponseToJson(
  ListDevicePlaces200Response instance,
) => <String, dynamic>{'items': instance.items.map((e) => e.toJson()).toList()};
