// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'watch_key_register.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$WatchKeyRegisterCWProxy {
  WatchKeyRegister orgId(String orgId);

  WatchKeyRegister fingerprint(String fingerprint);

  WatchKeyRegister platform(WatchPlatform platform);

  WatchKeyRegister name(String name);

  WatchKeyRegister model(String? model);

  WatchKeyRegister appVersion(String? appVersion);

  WatchKeyRegister osVersion(String? osVersion);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `WatchKeyRegister(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// WatchKeyRegister(...).copyWith(id: 12, name: "My name")
  /// ```
  WatchKeyRegister call({
    String orgId,
    String fingerprint,
    WatchPlatform platform,
    String name,
    String? model,
    String? appVersion,
    String? osVersion,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfWatchKeyRegister.copyWith(...)` or call `instanceOfWatchKeyRegister.copyWith.fieldName(value)` for a single field.
class _$WatchKeyRegisterCWProxyImpl implements _$WatchKeyRegisterCWProxy {
  const _$WatchKeyRegisterCWProxyImpl(this._value);

  final WatchKeyRegister _value;

  @override
  WatchKeyRegister orgId(String orgId) => call(orgId: orgId);

  @override
  WatchKeyRegister fingerprint(String fingerprint) =>
      call(fingerprint: fingerprint);

  @override
  WatchKeyRegister platform(WatchPlatform platform) => call(platform: platform);

  @override
  WatchKeyRegister name(String name) => call(name: name);

  @override
  WatchKeyRegister model(String? model) => call(model: model);

  @override
  WatchKeyRegister appVersion(String? appVersion) =>
      call(appVersion: appVersion);

  @override
  WatchKeyRegister osVersion(String? osVersion) => call(osVersion: osVersion);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `WatchKeyRegister(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// WatchKeyRegister(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  WatchKeyRegister call({
    Object? orgId = const $CopyWithPlaceholder(),
    Object? fingerprint = const $CopyWithPlaceholder(),
    Object? platform = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? model = const $CopyWithPlaceholder(),
    Object? appVersion = const $CopyWithPlaceholder(),
    Object? osVersion = const $CopyWithPlaceholder(),
  }) {
    return WatchKeyRegister(
      orgId: orgId == const $CopyWithPlaceholder() || orgId == null
          ? _value.orgId
          // ignore: cast_nullable_to_non_nullable
          : orgId as String,
      fingerprint:
          fingerprint == const $CopyWithPlaceholder() || fingerprint == null
          ? _value.fingerprint
          // ignore: cast_nullable_to_non_nullable
          : fingerprint as String,
      platform: platform == const $CopyWithPlaceholder() || platform == null
          ? _value.platform
          // ignore: cast_nullable_to_non_nullable
          : platform as WatchPlatform,
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      model: model == const $CopyWithPlaceholder()
          ? _value.model
          // ignore: cast_nullable_to_non_nullable
          : model as String?,
      appVersion: appVersion == const $CopyWithPlaceholder()
          ? _value.appVersion
          // ignore: cast_nullable_to_non_nullable
          : appVersion as String?,
      osVersion: osVersion == const $CopyWithPlaceholder()
          ? _value.osVersion
          // ignore: cast_nullable_to_non_nullable
          : osVersion as String?,
    );
  }
}

extension $WatchKeyRegisterCopyWith on WatchKeyRegister {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfWatchKeyRegister.copyWith(...)` or `instanceOfWatchKeyRegister.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$WatchKeyRegisterCWProxy get copyWith => _$WatchKeyRegisterCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WatchKeyRegister _$WatchKeyRegisterFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'WatchKeyRegister',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['org_id', 'fingerprint', 'platform', 'name'],
        );
        final val = WatchKeyRegister(
          orgId: $checkedConvert('org_id', (v) => v as String),
          fingerprint: $checkedConvert('fingerprint', (v) => v as String),
          platform: $checkedConvert(
            'platform',
            (v) => $enumDecode(_$WatchPlatformEnumMap, v),
          ),
          name: $checkedConvert('name', (v) => v as String),
          model: $checkedConvert('model', (v) => v as String?),
          appVersion: $checkedConvert('app_version', (v) => v as String?),
          osVersion: $checkedConvert('os_version', (v) => v as String?),
        );
        return val;
      },
      fieldKeyMap: const {
        'orgId': 'org_id',
        'appVersion': 'app_version',
        'osVersion': 'os_version',
      },
    );

Map<String, dynamic> _$WatchKeyRegisterToJson(WatchKeyRegister instance) =>
    <String, dynamic>{
      'org_id': instance.orgId,
      'fingerprint': instance.fingerprint,
      'platform': _$WatchPlatformEnumMap[instance.platform]!,
      'name': instance.name,
      'model': ?instance.model,
      'app_version': ?instance.appVersion,
      'os_version': ?instance.osVersion,
    };

const _$WatchPlatformEnumMap = {
  WatchPlatform.watchos: 'watchos',
  WatchPlatform.wearos: 'wearos',
};
