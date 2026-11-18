// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'list_device_sources200_response.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ListDeviceSources200ResponseCWProxy {
  ListDeviceSources200Response items(List<DeviceSource> items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ListDeviceSources200Response(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ListDeviceSources200Response(...).copyWith(id: 12, name: "My name")
  /// ```
  ListDeviceSources200Response call({List<DeviceSource> items});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfListDeviceSources200Response.copyWith(...)` or call `instanceOfListDeviceSources200Response.copyWith.fieldName(value)` for a single field.
class _$ListDeviceSources200ResponseCWProxyImpl
    implements _$ListDeviceSources200ResponseCWProxy {
  const _$ListDeviceSources200ResponseCWProxyImpl(this._value);

  final ListDeviceSources200Response _value;

  @override
  ListDeviceSources200Response items(List<DeviceSource> items) =>
      call(items: items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ListDeviceSources200Response(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ListDeviceSources200Response(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ListDeviceSources200Response call({
    Object? items = const $CopyWithPlaceholder(),
  }) {
    return ListDeviceSources200Response(
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<DeviceSource>,
    );
  }
}

extension $ListDeviceSources200ResponseCopyWith
    on ListDeviceSources200Response {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfListDeviceSources200Response.copyWith(...)` or `instanceOfListDeviceSources200Response.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ListDeviceSources200ResponseCWProxy get copyWith =>
      _$ListDeviceSources200ResponseCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ListDeviceSources200Response _$ListDeviceSources200ResponseFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('ListDeviceSources200Response', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['items']);
  final val = ListDeviceSources200Response(
    items: $checkedConvert(
      'items',
      (v) => (v as List<dynamic>)
          .map((e) => DeviceSource.fromJson(e as Map<String, dynamic>))
          .toList(),
    ),
  );
  return val;
});

Map<String, dynamic> _$ListDeviceSources200ResponseToJson(
  ListDeviceSources200Response instance,
) => <String, dynamic>{'items': instance.items.map((e) => e.toJson()).toList()};
