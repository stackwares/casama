// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_local_device_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CreateLocalDeviceRequestCWProxy {
  CreateLocalDeviceRequest orgId(String orgId);

  CreateLocalDeviceRequest name(String name);

  CreateLocalDeviceRequest platform(
    CreateLocalDeviceRequestPlatformEnum platform,
  );

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CreateLocalDeviceRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CreateLocalDeviceRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  CreateLocalDeviceRequest call({
    String orgId,
    String name,
    CreateLocalDeviceRequestPlatformEnum platform,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfCreateLocalDeviceRequest.copyWith(...)` or call `instanceOfCreateLocalDeviceRequest.copyWith.fieldName(value)` for a single field.
class _$CreateLocalDeviceRequestCWProxyImpl
    implements _$CreateLocalDeviceRequestCWProxy {
  const _$CreateLocalDeviceRequestCWProxyImpl(this._value);

  final CreateLocalDeviceRequest _value;

  @override
  CreateLocalDeviceRequest orgId(String orgId) => call(orgId: orgId);

  @override
  CreateLocalDeviceRequest name(String name) => call(name: name);

  @override
  CreateLocalDeviceRequest platform(
    CreateLocalDeviceRequestPlatformEnum platform,
  ) => call(platform: platform);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CreateLocalDeviceRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CreateLocalDeviceRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  CreateLocalDeviceRequest call({
    Object? orgId = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? platform = const $CopyWithPlaceholder(),
  }) {
    return CreateLocalDeviceRequest(
      orgId: orgId == const $CopyWithPlaceholder() || orgId == null
          ? _value.orgId
          // ignore: cast_nullable_to_non_nullable
          : orgId as String,
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      platform: platform == const $CopyWithPlaceholder() || platform == null
          ? _value.platform
          // ignore: cast_nullable_to_non_nullable
          : platform as CreateLocalDeviceRequestPlatformEnum,
    );
  }
}

extension $CreateLocalDeviceRequestCopyWith on CreateLocalDeviceRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfCreateLocalDeviceRequest.copyWith(...)` or `instanceOfCreateLocalDeviceRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CreateLocalDeviceRequestCWProxy get copyWith =>
      _$CreateLocalDeviceRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateLocalDeviceRequest _$CreateLocalDeviceRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('CreateLocalDeviceRequest', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['org_id', 'name', 'platform']);
  final val = CreateLocalDeviceRequest(
    orgId: $checkedConvert('org_id', (v) => v as String),
    name: $checkedConvert('name', (v) => v as String),
    platform: $checkedConvert(
      'platform',
      (v) => $enumDecode(_$CreateLocalDeviceRequestPlatformEnumEnumMap, v),
    ),
  );
  return val;
}, fieldKeyMap: const {'orgId': 'org_id'});

Map<String, dynamic> _$CreateLocalDeviceRequestToJson(
  CreateLocalDeviceRequest instance,
) => <String, dynamic>{
  'org_id': instance.orgId,
  'name': instance.name,
  'platform': _$CreateLocalDeviceRequestPlatformEnumEnumMap[instance.platform]!,
};

const _$CreateLocalDeviceRequestPlatformEnumEnumMap = {
  CreateLocalDeviceRequestPlatformEnum.macos: 'macos',
  CreateLocalDeviceRequestPlatformEnum.windows: 'windows',
  CreateLocalDeviceRequestPlatformEnum.linux: 'linux',
};
