// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'list_device_grants200_response.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ListDeviceGrants200ResponseCWProxy {
  ListDeviceGrants200Response items(List<DeviceGrant> items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ListDeviceGrants200Response(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ListDeviceGrants200Response(...).copyWith(id: 12, name: "My name")
  /// ```
  ListDeviceGrants200Response call({List<DeviceGrant> items});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfListDeviceGrants200Response.copyWith(...)` or call `instanceOfListDeviceGrants200Response.copyWith.fieldName(value)` for a single field.
class _$ListDeviceGrants200ResponseCWProxyImpl
    implements _$ListDeviceGrants200ResponseCWProxy {
  const _$ListDeviceGrants200ResponseCWProxyImpl(this._value);

  final ListDeviceGrants200Response _value;

  @override
  ListDeviceGrants200Response items(List<DeviceGrant> items) =>
      call(items: items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ListDeviceGrants200Response(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ListDeviceGrants200Response(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ListDeviceGrants200Response call({
    Object? items = const $CopyWithPlaceholder(),
  }) {
    return ListDeviceGrants200Response(
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<DeviceGrant>,
    );
  }
}

extension $ListDeviceGrants200ResponseCopyWith on ListDeviceGrants200Response {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfListDeviceGrants200Response.copyWith(...)` or `instanceOfListDeviceGrants200Response.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ListDeviceGrants200ResponseCWProxy get copyWith =>
      _$ListDeviceGrants200ResponseCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ListDeviceGrants200Response _$ListDeviceGrants200ResponseFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('ListDeviceGrants200Response', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['items']);
  final val = ListDeviceGrants200Response(
    items: $checkedConvert(
      'items',
      (v) => (v as List<dynamic>)
          .map((e) => DeviceGrant.fromJson(e as Map<String, dynamic>))
          .toList(),
    ),
  );
  return val;
});

Map<String, dynamic> _$ListDeviceGrants200ResponseToJson(
  ListDeviceGrants200Response instance,
) => <String, dynamic>{'items': instance.items.map((e) => e.toJson()).toList()};
