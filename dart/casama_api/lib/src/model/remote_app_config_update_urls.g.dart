// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'remote_app_config_update_urls.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$RemoteAppConfigUpdateUrlsCWProxy {
  RemoteAppConfigUpdateUrls ios(String? ios);

  RemoteAppConfigUpdateUrls android(String? android);

  RemoteAppConfigUpdateUrls macos(String? macos);

  RemoteAppConfigUpdateUrls windows(String? windows);

  RemoteAppConfigUpdateUrls linux(String? linux);

  RemoteAppConfigUpdateUrls web(String? web);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `RemoteAppConfigUpdateUrls(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// RemoteAppConfigUpdateUrls(...).copyWith(id: 12, name: "My name")
  /// ```
  RemoteAppConfigUpdateUrls call({
    String? ios,
    String? android,
    String? macos,
    String? windows,
    String? linux,
    String? web,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfRemoteAppConfigUpdateUrls.copyWith(...)` or call `instanceOfRemoteAppConfigUpdateUrls.copyWith.fieldName(value)` for a single field.
class _$RemoteAppConfigUpdateUrlsCWProxyImpl
    implements _$RemoteAppConfigUpdateUrlsCWProxy {
  const _$RemoteAppConfigUpdateUrlsCWProxyImpl(this._value);

  final RemoteAppConfigUpdateUrls _value;

  @override
  RemoteAppConfigUpdateUrls ios(String? ios) => call(ios: ios);

  @override
  RemoteAppConfigUpdateUrls android(String? android) => call(android: android);

  @override
  RemoteAppConfigUpdateUrls macos(String? macos) => call(macos: macos);

  @override
  RemoteAppConfigUpdateUrls windows(String? windows) => call(windows: windows);

  @override
  RemoteAppConfigUpdateUrls linux(String? linux) => call(linux: linux);

  @override
  RemoteAppConfigUpdateUrls web(String? web) => call(web: web);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `RemoteAppConfigUpdateUrls(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// RemoteAppConfigUpdateUrls(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  RemoteAppConfigUpdateUrls call({
    Object? ios = const $CopyWithPlaceholder(),
    Object? android = const $CopyWithPlaceholder(),
    Object? macos = const $CopyWithPlaceholder(),
    Object? windows = const $CopyWithPlaceholder(),
    Object? linux = const $CopyWithPlaceholder(),
    Object? web = const $CopyWithPlaceholder(),
  }) {
    return RemoteAppConfigUpdateUrls(
      ios: ios == const $CopyWithPlaceholder()
          ? _value.ios
          // ignore: cast_nullable_to_non_nullable
          : ios as String?,
      android: android == const $CopyWithPlaceholder()
          ? _value.android
          // ignore: cast_nullable_to_non_nullable
          : android as String?,
      macos: macos == const $CopyWithPlaceholder()
          ? _value.macos
          // ignore: cast_nullable_to_non_nullable
          : macos as String?,
      windows: windows == const $CopyWithPlaceholder()
          ? _value.windows
          // ignore: cast_nullable_to_non_nullable
          : windows as String?,
      linux: linux == const $CopyWithPlaceholder()
          ? _value.linux
          // ignore: cast_nullable_to_non_nullable
          : linux as String?,
      web: web == const $CopyWithPlaceholder()
          ? _value.web
          // ignore: cast_nullable_to_non_nullable
          : web as String?,
    );
  }
}

extension $RemoteAppConfigUpdateUrlsCopyWith on RemoteAppConfigUpdateUrls {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfRemoteAppConfigUpdateUrls.copyWith(...)` or `instanceOfRemoteAppConfigUpdateUrls.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$RemoteAppConfigUpdateUrlsCWProxy get copyWith =>
      _$RemoteAppConfigUpdateUrlsCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RemoteAppConfigUpdateUrls _$RemoteAppConfigUpdateUrlsFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('RemoteAppConfigUpdateUrls', json, ($checkedConvert) {
  final val = RemoteAppConfigUpdateUrls(
    ios: $checkedConvert('ios', (v) => v as String?),
    android: $checkedConvert('android', (v) => v as String?),
    macos: $checkedConvert('macos', (v) => v as String?),
    windows: $checkedConvert('windows', (v) => v as String?),
    linux: $checkedConvert('linux', (v) => v as String?),
    web: $checkedConvert('web', (v) => v as String?),
  );
  return val;
});

Map<String, dynamic> _$RemoteAppConfigUpdateUrlsToJson(
  RemoteAppConfigUpdateUrls instance,
) => <String, dynamic>{
  'ios': ?instance.ios,
  'android': ?instance.android,
  'macos': ?instance.macos,
  'windows': ?instance.windows,
  'linux': ?instance.linux,
  'web': ?instance.web,
};
