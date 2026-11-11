// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'list_device_requests200_response.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ListDeviceRequests200ResponseCWProxy {
  ListDeviceRequests200Response items(List<DeviceRequest> items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ListDeviceRequests200Response(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ListDeviceRequests200Response(...).copyWith(id: 12, name: "My name")
  /// ```
  ListDeviceRequests200Response call({List<DeviceRequest> items});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfListDeviceRequests200Response.copyWith(...)` or call `instanceOfListDeviceRequests200Response.copyWith.fieldName(value)` for a single field.
class _$ListDeviceRequests200ResponseCWProxyImpl
    implements _$ListDeviceRequests200ResponseCWProxy {
  const _$ListDeviceRequests200ResponseCWProxyImpl(this._value);

  final ListDeviceRequests200Response _value;

  @override
  ListDeviceRequests200Response items(List<DeviceRequest> items) =>
      call(items: items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ListDeviceRequests200Response(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ListDeviceRequests200Response(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ListDeviceRequests200Response call({
    Object? items = const $CopyWithPlaceholder(),
  }) {
    return ListDeviceRequests200Response(
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<DeviceRequest>,
    );
  }
}

extension $ListDeviceRequests200ResponseCopyWith
    on ListDeviceRequests200Response {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfListDeviceRequests200Response.copyWith(...)` or `instanceOfListDeviceRequests200Response.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ListDeviceRequests200ResponseCWProxy get copyWith =>
      _$ListDeviceRequests200ResponseCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ListDeviceRequests200Response _$ListDeviceRequests200ResponseFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('ListDeviceRequests200Response', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['items']);
  final val = ListDeviceRequests200Response(
    items: $checkedConvert(
      'items',
      (v) => (v as List<dynamic>)
          .map((e) => DeviceRequest.fromJson(e as Map<String, dynamic>))
          .toList(),
    ),
  );
  return val;
});

Map<String, dynamic> _$ListDeviceRequests200ResponseToJson(
  ListDeviceRequests200Response instance,
) => <String, dynamic>{'items': instance.items.map((e) => e.toJson()).toList()};
