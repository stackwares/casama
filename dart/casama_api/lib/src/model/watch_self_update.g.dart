// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'watch_self_update.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$WatchSelfUpdateCWProxy {
  WatchSelfUpdate pushToken(String? pushToken);

  WatchSelfUpdate pushKind(WatchSelfUpdatePushKindEnum? pushKind);

  WatchSelfUpdate sandbox(bool? sandbox);

  WatchSelfUpdate appVersion(String? appVersion);

  WatchSelfUpdate osVersion(String? osVersion);

  WatchSelfUpdate name(String? name);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `WatchSelfUpdate(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// WatchSelfUpdate(...).copyWith(id: 12, name: "My name")
  /// ```
  WatchSelfUpdate call({
    String? pushToken,
    WatchSelfUpdatePushKindEnum? pushKind,
    bool? sandbox,
    String? appVersion,
    String? osVersion,
    String? name,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfWatchSelfUpdate.copyWith(...)` or call `instanceOfWatchSelfUpdate.copyWith.fieldName(value)` for a single field.
class _$WatchSelfUpdateCWProxyImpl implements _$WatchSelfUpdateCWProxy {
  const _$WatchSelfUpdateCWProxyImpl(this._value);

  final WatchSelfUpdate _value;

  @override
  WatchSelfUpdate pushToken(String? pushToken) => call(pushToken: pushToken);

  @override
  WatchSelfUpdate pushKind(WatchSelfUpdatePushKindEnum? pushKind) =>
      call(pushKind: pushKind);

  @override
  WatchSelfUpdate sandbox(bool? sandbox) => call(sandbox: sandbox);

  @override
  WatchSelfUpdate appVersion(String? appVersion) =>
      call(appVersion: appVersion);

  @override
  WatchSelfUpdate osVersion(String? osVersion) => call(osVersion: osVersion);

  @override
  WatchSelfUpdate name(String? name) => call(name: name);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `WatchSelfUpdate(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// WatchSelfUpdate(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  WatchSelfUpdate call({
    Object? pushToken = const $CopyWithPlaceholder(),
    Object? pushKind = const $CopyWithPlaceholder(),
    Object? sandbox = const $CopyWithPlaceholder(),
    Object? appVersion = const $CopyWithPlaceholder(),
    Object? osVersion = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
  }) {
    return WatchSelfUpdate(
      pushToken: pushToken == const $CopyWithPlaceholder()
          ? _value.pushToken
          // ignore: cast_nullable_to_non_nullable
          : pushToken as String?,
      pushKind: pushKind == const $CopyWithPlaceholder()
          ? _value.pushKind
          // ignore: cast_nullable_to_non_nullable
          : pushKind as WatchSelfUpdatePushKindEnum?,
      sandbox: sandbox == const $CopyWithPlaceholder()
          ? _value.sandbox
          // ignore: cast_nullable_to_non_nullable
          : sandbox as bool?,
      appVersion: appVersion == const $CopyWithPlaceholder()
          ? _value.appVersion
          // ignore: cast_nullable_to_non_nullable
          : appVersion as String?,
      osVersion: osVersion == const $CopyWithPlaceholder()
          ? _value.osVersion
          // ignore: cast_nullable_to_non_nullable
          : osVersion as String?,
      name: name == const $CopyWithPlaceholder()
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String?,
    );
  }
}

extension $WatchSelfUpdateCopyWith on WatchSelfUpdate {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfWatchSelfUpdate.copyWith(...)` or `instanceOfWatchSelfUpdate.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$WatchSelfUpdateCWProxy get copyWith => _$WatchSelfUpdateCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WatchSelfUpdate _$WatchSelfUpdateFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'WatchSelfUpdate',
      json,
      ($checkedConvert) {
        final val = WatchSelfUpdate(
          pushToken: $checkedConvert('push_token', (v) => v as String?),
          pushKind: $checkedConvert(
            'push_kind',
            (v) => $enumDecodeNullable(_$WatchSelfUpdatePushKindEnumEnumMap, v),
          ),
          sandbox: $checkedConvert('sandbox', (v) => v as bool?),
          appVersion: $checkedConvert('app_version', (v) => v as String?),
          osVersion: $checkedConvert('os_version', (v) => v as String?),
          name: $checkedConvert('name', (v) => v as String?),
        );
        return val;
      },
      fieldKeyMap: const {
        'pushToken': 'push_token',
        'pushKind': 'push_kind',
        'appVersion': 'app_version',
        'osVersion': 'os_version',
      },
    );

Map<String, dynamic> _$WatchSelfUpdateToJson(WatchSelfUpdate instance) =>
    <String, dynamic>{
      'push_token': ?instance.pushToken,
      'push_kind': ?_$WatchSelfUpdatePushKindEnumEnumMap[instance.pushKind],
      'sandbox': ?instance.sandbox,
      'app_version': ?instance.appVersion,
      'os_version': ?instance.osVersion,
      'name': ?instance.name,
    };

const _$WatchSelfUpdatePushKindEnumEnumMap = {
  WatchSelfUpdatePushKindEnum.apns: 'apns',
  WatchSelfUpdatePushKindEnum.fcm: 'fcm',
};
