// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'deleted_device.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$DeletedDeviceCWProxy {
  DeletedDevice deleted(String deleted);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DeletedDevice(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DeletedDevice(...).copyWith(id: 12, name: "My name")
  /// ```
  DeletedDevice call({String deleted});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfDeletedDevice.copyWith(...)` or call `instanceOfDeletedDevice.copyWith.fieldName(value)` for a single field.
class _$DeletedDeviceCWProxyImpl implements _$DeletedDeviceCWProxy {
  const _$DeletedDeviceCWProxyImpl(this._value);

  final DeletedDevice _value;

  @override
  DeletedDevice deleted(String deleted) => call(deleted: deleted);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DeletedDevice(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DeletedDevice(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  DeletedDevice call({Object? deleted = const $CopyWithPlaceholder()}) {
    return DeletedDevice(
      deleted: deleted == const $CopyWithPlaceholder() || deleted == null
          ? _value.deleted
          // ignore: cast_nullable_to_non_nullable
          : deleted as String,
    );
  }
}

extension $DeletedDeviceCopyWith on DeletedDevice {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfDeletedDevice.copyWith(...)` or `instanceOfDeletedDevice.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$DeletedDeviceCWProxy get copyWith => _$DeletedDeviceCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeletedDevice _$DeletedDeviceFromJson(Map<String, dynamic> json) =>
    $checkedCreate('DeletedDevice', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['deleted']);
      final val = DeletedDevice(
        deleted: $checkedConvert('deleted', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$DeletedDeviceToJson(DeletedDevice instance) =>
    <String, dynamic>{'deleted': instance.deleted};
