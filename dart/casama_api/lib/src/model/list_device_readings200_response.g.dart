// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'list_device_readings200_response.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ListDeviceReadings200ResponseCWProxy {
  ListDeviceReadings200Response items(List<DeviceReading> items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ListDeviceReadings200Response(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ListDeviceReadings200Response(...).copyWith(id: 12, name: "My name")
  /// ```
  ListDeviceReadings200Response call({List<DeviceReading> items});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfListDeviceReadings200Response.copyWith(...)` or call `instanceOfListDeviceReadings200Response.copyWith.fieldName(value)` for a single field.
class _$ListDeviceReadings200ResponseCWProxyImpl
    implements _$ListDeviceReadings200ResponseCWProxy {
  const _$ListDeviceReadings200ResponseCWProxyImpl(this._value);

  final ListDeviceReadings200Response _value;

  @override
  ListDeviceReadings200Response items(List<DeviceReading> items) =>
      call(items: items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ListDeviceReadings200Response(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ListDeviceReadings200Response(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ListDeviceReadings200Response call({
    Object? items = const $CopyWithPlaceholder(),
  }) {
    return ListDeviceReadings200Response(
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<DeviceReading>,
    );
  }
}

extension $ListDeviceReadings200ResponseCopyWith
    on ListDeviceReadings200Response {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfListDeviceReadings200Response.copyWith(...)` or `instanceOfListDeviceReadings200Response.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ListDeviceReadings200ResponseCWProxy get copyWith =>
      _$ListDeviceReadings200ResponseCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ListDeviceReadings200Response _$ListDeviceReadings200ResponseFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('ListDeviceReadings200Response', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['items']);
  final val = ListDeviceReadings200Response(
    items: $checkedConvert(
      'items',
      (v) => (v as List<dynamic>)
          .map((e) => DeviceReading.fromJson(e as Map<String, dynamic>))
          .toList(),
    ),
  );
  return val;
});

Map<String, dynamic> _$ListDeviceReadings200ResponseToJson(
  ListDeviceReadings200Response instance,
) => <String, dynamic>{'items': instance.items.map((e) => e.toJson()).toList()};
