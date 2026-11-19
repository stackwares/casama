// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'remote_app_config_crash_reporter.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$RemoteAppConfigCrashReporterCWProxy {
  RemoteAppConfigCrashReporter default_(String? default_);

  RemoteAppConfigCrashReporter ios(String? ios);

  RemoteAppConfigCrashReporter android(String? android);

  RemoteAppConfigCrashReporter macos(String? macos);

  RemoteAppConfigCrashReporter windows(String? windows);

  RemoteAppConfigCrashReporter linux(String? linux);

  RemoteAppConfigCrashReporter web(String? web);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `RemoteAppConfigCrashReporter(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// RemoteAppConfigCrashReporter(...).copyWith(id: 12, name: "My name")
  /// ```
  RemoteAppConfigCrashReporter call({
    String? default_,
    String? ios,
    String? android,
    String? macos,
    String? windows,
    String? linux,
    String? web,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfRemoteAppConfigCrashReporter.copyWith(...)` or call `instanceOfRemoteAppConfigCrashReporter.copyWith.fieldName(value)` for a single field.
class _$RemoteAppConfigCrashReporterCWProxyImpl
    implements _$RemoteAppConfigCrashReporterCWProxy {
  const _$RemoteAppConfigCrashReporterCWProxyImpl(this._value);

  final RemoteAppConfigCrashReporter _value;

  @override
  RemoteAppConfigCrashReporter default_(String? default_) =>
      call(default_: default_);

  @override
  RemoteAppConfigCrashReporter ios(String? ios) => call(ios: ios);

  @override
  RemoteAppConfigCrashReporter android(String? android) =>
      call(android: android);

  @override
  RemoteAppConfigCrashReporter macos(String? macos) => call(macos: macos);

  @override
  RemoteAppConfigCrashReporter windows(String? windows) =>
      call(windows: windows);

  @override
  RemoteAppConfigCrashReporter linux(String? linux) => call(linux: linux);

  @override
  RemoteAppConfigCrashReporter web(String? web) => call(web: web);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `RemoteAppConfigCrashReporter(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// RemoteAppConfigCrashReporter(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  RemoteAppConfigCrashReporter call({
    Object? default_ = const $CopyWithPlaceholder(),
    Object? ios = const $CopyWithPlaceholder(),
    Object? android = const $CopyWithPlaceholder(),
    Object? macos = const $CopyWithPlaceholder(),
    Object? windows = const $CopyWithPlaceholder(),
    Object? linux = const $CopyWithPlaceholder(),
    Object? web = const $CopyWithPlaceholder(),
  }) {
    return RemoteAppConfigCrashReporter(
      default_: default_ == const $CopyWithPlaceholder()
          ? _value.default_
          // ignore: cast_nullable_to_non_nullable
          : default_ as String?,
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

extension $RemoteAppConfigCrashReporterCopyWith
    on RemoteAppConfigCrashReporter {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfRemoteAppConfigCrashReporter.copyWith(...)` or `instanceOfRemoteAppConfigCrashReporter.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$RemoteAppConfigCrashReporterCWProxy get copyWith =>
      _$RemoteAppConfigCrashReporterCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RemoteAppConfigCrashReporter _$RemoteAppConfigCrashReporterFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('RemoteAppConfigCrashReporter', json, ($checkedConvert) {
  final val = RemoteAppConfigCrashReporter(
    default_: $checkedConvert('default', (v) => v as String?),
    ios: $checkedConvert('ios', (v) => v as String?),
    android: $checkedConvert('android', (v) => v as String?),
    macos: $checkedConvert('macos', (v) => v as String?),
    windows: $checkedConvert('windows', (v) => v as String?),
    linux: $checkedConvert('linux', (v) => v as String?),
    web: $checkedConvert('web', (v) => v as String?),
  );
  return val;
}, fieldKeyMap: const {'default_': 'default'});

Map<String, dynamic> _$RemoteAppConfigCrashReporterToJson(
  RemoteAppConfigCrashReporter instance,
) => <String, dynamic>{
  'default': ?instance.default_,
  'ios': ?instance.ios,
  'android': ?instance.android,
  'macos': ?instance.macos,
  'windows': ?instance.windows,
  'linux': ?instance.linux,
  'web': ?instance.web,
};
