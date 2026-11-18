// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'list_device_permissions200_response.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ListDevicePermissions200ResponseCWProxy {
  ListDevicePermissions200Response items(List<DevicePermissions> items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ListDevicePermissions200Response(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ListDevicePermissions200Response(...).copyWith(id: 12, name: "My name")
  /// ```
  ListDevicePermissions200Response call({List<DevicePermissions> items});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfListDevicePermissions200Response.copyWith(...)` or call `instanceOfListDevicePermissions200Response.copyWith.fieldName(value)` for a single field.
class _$ListDevicePermissions200ResponseCWProxyImpl
    implements _$ListDevicePermissions200ResponseCWProxy {
  const _$ListDevicePermissions200ResponseCWProxyImpl(this._value);

  final ListDevicePermissions200Response _value;

  @override
  ListDevicePermissions200Response items(List<DevicePermissions> items) =>
      call(items: items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ListDevicePermissions200Response(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ListDevicePermissions200Response(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ListDevicePermissions200Response call({
    Object? items = const $CopyWithPlaceholder(),
  }) {
    return ListDevicePermissions200Response(
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<DevicePermissions>,
    );
  }
}

extension $ListDevicePermissions200ResponseCopyWith
    on ListDevicePermissions200Response {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfListDevicePermissions200Response.copyWith(...)` or `instanceOfListDevicePermissions200Response.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ListDevicePermissions200ResponseCWProxy get copyWith =>
      _$ListDevicePermissions200ResponseCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ListDevicePermissions200Response _$ListDevicePermissions200ResponseFromJson(
  Map<String, dynamic> json,
) =>
    $checkedCreate('ListDevicePermissions200Response', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items']);
      final val = ListDevicePermissions200Response(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => DevicePermissions.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$ListDevicePermissions200ResponseToJson(
  ListDevicePermissions200Response instance,
) => <String, dynamic>{'items': instance.items.map((e) => e.toJson()).toList()};
