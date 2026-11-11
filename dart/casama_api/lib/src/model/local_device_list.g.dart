// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_device_list.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$LocalDeviceListCWProxy {
  LocalDeviceList items(List<LocalDevice> items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `LocalDeviceList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// LocalDeviceList(...).copyWith(id: 12, name: "My name")
  /// ```
  LocalDeviceList call({List<LocalDevice> items});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfLocalDeviceList.copyWith(...)` or call `instanceOfLocalDeviceList.copyWith.fieldName(value)` for a single field.
class _$LocalDeviceListCWProxyImpl implements _$LocalDeviceListCWProxy {
  const _$LocalDeviceListCWProxyImpl(this._value);

  final LocalDeviceList _value;

  @override
  LocalDeviceList items(List<LocalDevice> items) => call(items: items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `LocalDeviceList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// LocalDeviceList(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  LocalDeviceList call({Object? items = const $CopyWithPlaceholder()}) {
    return LocalDeviceList(
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<LocalDevice>,
    );
  }
}

extension $LocalDeviceListCopyWith on LocalDeviceList {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfLocalDeviceList.copyWith(...)` or `instanceOfLocalDeviceList.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$LocalDeviceListCWProxy get copyWith => _$LocalDeviceListCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LocalDeviceList _$LocalDeviceListFromJson(Map<String, dynamic> json) =>
    $checkedCreate('LocalDeviceList', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items']);
      final val = LocalDeviceList(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => LocalDevice.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$LocalDeviceListToJson(LocalDeviceList instance) =>
    <String, dynamic>{'items': instance.items.map((e) => e.toJson()).toList()};
