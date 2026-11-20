// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'add_admin_device_key_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AddAdminDeviceKeyRequestCWProxy {
  AddAdminDeviceKeyRequest name(String name);

  AddAdminDeviceKeyRequest publicKey(String publicKey);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AddAdminDeviceKeyRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AddAdminDeviceKeyRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  AddAdminDeviceKeyRequest call({String name, String publicKey});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfAddAdminDeviceKeyRequest.copyWith(...)` or call `instanceOfAddAdminDeviceKeyRequest.copyWith.fieldName(value)` for a single field.
class _$AddAdminDeviceKeyRequestCWProxyImpl
    implements _$AddAdminDeviceKeyRequestCWProxy {
  const _$AddAdminDeviceKeyRequestCWProxyImpl(this._value);

  final AddAdminDeviceKeyRequest _value;

  @override
  AddAdminDeviceKeyRequest name(String name) => call(name: name);

  @override
  AddAdminDeviceKeyRequest publicKey(String publicKey) =>
      call(publicKey: publicKey);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AddAdminDeviceKeyRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AddAdminDeviceKeyRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  AddAdminDeviceKeyRequest call({
    Object? name = const $CopyWithPlaceholder(),
    Object? publicKey = const $CopyWithPlaceholder(),
  }) {
    return AddAdminDeviceKeyRequest(
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      publicKey: publicKey == const $CopyWithPlaceholder() || publicKey == null
          ? _value.publicKey
          // ignore: cast_nullable_to_non_nullable
          : publicKey as String,
    );
  }
}

extension $AddAdminDeviceKeyRequestCopyWith on AddAdminDeviceKeyRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfAddAdminDeviceKeyRequest.copyWith(...)` or `instanceOfAddAdminDeviceKeyRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AddAdminDeviceKeyRequestCWProxy get copyWith =>
      _$AddAdminDeviceKeyRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AddAdminDeviceKeyRequest _$AddAdminDeviceKeyRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('AddAdminDeviceKeyRequest', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['name', 'public_key']);
  final val = AddAdminDeviceKeyRequest(
    name: $checkedConvert('name', (v) => v as String),
    publicKey: $checkedConvert('public_key', (v) => v as String),
  );
  return val;
}, fieldKeyMap: const {'publicKey': 'public_key'});

Map<String, dynamic> _$AddAdminDeviceKeyRequestToJson(
  AddAdminDeviceKeyRequest instance,
) => <String, dynamic>{'name': instance.name, 'public_key': instance.publicKey};
