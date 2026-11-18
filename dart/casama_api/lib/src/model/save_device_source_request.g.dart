// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'save_device_source_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SaveDeviceSourceRequestCWProxy {
  SaveDeviceSourceRequest name(String name);

  SaveDeviceSourceRequest platform(
    SaveDeviceSourceRequestPlatformEnum platform,
  );

  SaveDeviceSourceRequest kinds(SaveDeviceSourceRequestKinds kinds);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SaveDeviceSourceRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SaveDeviceSourceRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  SaveDeviceSourceRequest call({
    String name,
    SaveDeviceSourceRequestPlatformEnum platform,
    SaveDeviceSourceRequestKinds kinds,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfSaveDeviceSourceRequest.copyWith(...)` or call `instanceOfSaveDeviceSourceRequest.copyWith.fieldName(value)` for a single field.
class _$SaveDeviceSourceRequestCWProxyImpl
    implements _$SaveDeviceSourceRequestCWProxy {
  const _$SaveDeviceSourceRequestCWProxyImpl(this._value);

  final SaveDeviceSourceRequest _value;

  @override
  SaveDeviceSourceRequest name(String name) => call(name: name);

  @override
  SaveDeviceSourceRequest platform(
    SaveDeviceSourceRequestPlatformEnum platform,
  ) => call(platform: platform);

  @override
  SaveDeviceSourceRequest kinds(SaveDeviceSourceRequestKinds kinds) =>
      call(kinds: kinds);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SaveDeviceSourceRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SaveDeviceSourceRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  SaveDeviceSourceRequest call({
    Object? name = const $CopyWithPlaceholder(),
    Object? platform = const $CopyWithPlaceholder(),
    Object? kinds = const $CopyWithPlaceholder(),
  }) {
    return SaveDeviceSourceRequest(
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      platform: platform == const $CopyWithPlaceholder() || platform == null
          ? _value.platform
          // ignore: cast_nullable_to_non_nullable
          : platform as SaveDeviceSourceRequestPlatformEnum,
      kinds: kinds == const $CopyWithPlaceholder() || kinds == null
          ? _value.kinds
          // ignore: cast_nullable_to_non_nullable
          : kinds as SaveDeviceSourceRequestKinds,
    );
  }
}

extension $SaveDeviceSourceRequestCopyWith on SaveDeviceSourceRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfSaveDeviceSourceRequest.copyWith(...)` or `instanceOfSaveDeviceSourceRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SaveDeviceSourceRequestCWProxy get copyWith =>
      _$SaveDeviceSourceRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SaveDeviceSourceRequest _$SaveDeviceSourceRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('SaveDeviceSourceRequest', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['name', 'platform', 'kinds']);
  final val = SaveDeviceSourceRequest(
    name: $checkedConvert('name', (v) => v as String),
    platform: $checkedConvert(
      'platform',
      (v) => $enumDecode(_$SaveDeviceSourceRequestPlatformEnumEnumMap, v),
    ),
    kinds: $checkedConvert(
      'kinds',
      (v) => SaveDeviceSourceRequestKinds.fromJson(v as Map<String, dynamic>),
    ),
  );
  return val;
});

Map<String, dynamic> _$SaveDeviceSourceRequestToJson(
  SaveDeviceSourceRequest instance,
) => <String, dynamic>{
  'name': instance.name,
  'platform': _$SaveDeviceSourceRequestPlatformEnumEnumMap[instance.platform]!,
  'kinds': instance.kinds.toJson(),
};

const _$SaveDeviceSourceRequestPlatformEnumEnumMap = {
  SaveDeviceSourceRequestPlatformEnum.ios: 'ios',
  SaveDeviceSourceRequestPlatformEnum.android: 'android',
  SaveDeviceSourceRequestPlatformEnum.macos: 'macos',
  SaveDeviceSourceRequestPlatformEnum.windows: 'windows',
  SaveDeviceSourceRequestPlatformEnum.linux: 'linux',
  SaveDeviceSourceRequestPlatformEnum.web: 'web',
};
