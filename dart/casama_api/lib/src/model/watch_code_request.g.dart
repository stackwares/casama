// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'watch_code_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$WatchCodeRequestCWProxy {
  WatchCodeRequest fingerprint(String fingerprint);

  WatchCodeRequest platform(WatchPlatform platform);

  WatchCodeRequest name(String name);

  WatchCodeRequest model(String? model);

  WatchCodeRequest appVersion(String? appVersion);

  WatchCodeRequest osVersion(String? osVersion);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `WatchCodeRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// WatchCodeRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  WatchCodeRequest call({
    String fingerprint,
    WatchPlatform platform,
    String name,
    String? model,
    String? appVersion,
    String? osVersion,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfWatchCodeRequest.copyWith(...)` or call `instanceOfWatchCodeRequest.copyWith.fieldName(value)` for a single field.
class _$WatchCodeRequestCWProxyImpl implements _$WatchCodeRequestCWProxy {
  const _$WatchCodeRequestCWProxyImpl(this._value);

  final WatchCodeRequest _value;

  @override
  WatchCodeRequest fingerprint(String fingerprint) =>
      call(fingerprint: fingerprint);

  @override
  WatchCodeRequest platform(WatchPlatform platform) => call(platform: platform);

  @override
  WatchCodeRequest name(String name) => call(name: name);

  @override
  WatchCodeRequest model(String? model) => call(model: model);

  @override
  WatchCodeRequest appVersion(String? appVersion) =>
      call(appVersion: appVersion);

  @override
  WatchCodeRequest osVersion(String? osVersion) => call(osVersion: osVersion);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `WatchCodeRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// WatchCodeRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  WatchCodeRequest call({
    Object? fingerprint = const $CopyWithPlaceholder(),
    Object? platform = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? model = const $CopyWithPlaceholder(),
    Object? appVersion = const $CopyWithPlaceholder(),
    Object? osVersion = const $CopyWithPlaceholder(),
  }) {
    return WatchCodeRequest(
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

extension $WatchCodeRequestCopyWith on WatchCodeRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfWatchCodeRequest.copyWith(...)` or `instanceOfWatchCodeRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$WatchCodeRequestCWProxy get copyWith => _$WatchCodeRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WatchCodeRequest _$WatchCodeRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('WatchCodeRequest', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['fingerprint', 'platform', 'name']);
  final val = WatchCodeRequest(
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
}, fieldKeyMap: const {'appVersion': 'app_version', 'osVersion': 'os_version'});

Map<String, dynamic> _$WatchCodeRequestToJson(WatchCodeRequest instance) =>
    <String, dynamic>{
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
