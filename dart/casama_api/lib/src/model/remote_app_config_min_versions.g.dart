// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'remote_app_config_min_versions.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$RemoteAppConfigMinVersionsCWProxy {
  RemoteAppConfigMinVersions ios(String? ios);

  RemoteAppConfigMinVersions android(String? android);

  RemoteAppConfigMinVersions macos(String? macos);

  RemoteAppConfigMinVersions windows(String? windows);

  RemoteAppConfigMinVersions linux(String? linux);

  RemoteAppConfigMinVersions web(String? web);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `RemoteAppConfigMinVersions(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// RemoteAppConfigMinVersions(...).copyWith(id: 12, name: "My name")
  /// ```
  RemoteAppConfigMinVersions call({
    String? ios,
    String? android,
    String? macos,
    String? windows,
    String? linux,
    String? web,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfRemoteAppConfigMinVersions.copyWith(...)` or call `instanceOfRemoteAppConfigMinVersions.copyWith.fieldName(value)` for a single field.
class _$RemoteAppConfigMinVersionsCWProxyImpl
    implements _$RemoteAppConfigMinVersionsCWProxy {
  const _$RemoteAppConfigMinVersionsCWProxyImpl(this._value);

  final RemoteAppConfigMinVersions _value;

  @override
  RemoteAppConfigMinVersions ios(String? ios) => call(ios: ios);

  @override
  RemoteAppConfigMinVersions android(String? android) => call(android: android);

  @override
  RemoteAppConfigMinVersions macos(String? macos) => call(macos: macos);

  @override
  RemoteAppConfigMinVersions windows(String? windows) => call(windows: windows);

  @override
  RemoteAppConfigMinVersions linux(String? linux) => call(linux: linux);

  @override
  RemoteAppConfigMinVersions web(String? web) => call(web: web);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `RemoteAppConfigMinVersions(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// RemoteAppConfigMinVersions(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  RemoteAppConfigMinVersions call({
    Object? ios = const $CopyWithPlaceholder(),
    Object? android = const $CopyWithPlaceholder(),
    Object? macos = const $CopyWithPlaceholder(),
    Object? windows = const $CopyWithPlaceholder(),
    Object? linux = const $CopyWithPlaceholder(),
    Object? web = const $CopyWithPlaceholder(),
  }) {
    return RemoteAppConfigMinVersions(
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

extension $RemoteAppConfigMinVersionsCopyWith on RemoteAppConfigMinVersions {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfRemoteAppConfigMinVersions.copyWith(...)` or `instanceOfRemoteAppConfigMinVersions.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$RemoteAppConfigMinVersionsCWProxy get copyWith =>
      _$RemoteAppConfigMinVersionsCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RemoteAppConfigMinVersions _$RemoteAppConfigMinVersionsFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('RemoteAppConfigMinVersions', json, ($checkedConvert) {
  final val = RemoteAppConfigMinVersions(
    ios: $checkedConvert('ios', (v) => v as String?),
    android: $checkedConvert('android', (v) => v as String?),
    macos: $checkedConvert('macos', (v) => v as String?),
    windows: $checkedConvert('windows', (v) => v as String?),
    linux: $checkedConvert('linux', (v) => v as String?),
    web: $checkedConvert('web', (v) => v as String?),
  );
  return val;
});

Map<String, dynamic> _$RemoteAppConfigMinVersionsToJson(
  RemoteAppConfigMinVersions instance,
) => <String, dynamic>{
  'ios': ?instance.ios,
  'android': ?instance.android,
  'macos': ?instance.macos,
  'windows': ?instance.windows,
  'linux': ?instance.linux,
  'web': ?instance.web,
};
