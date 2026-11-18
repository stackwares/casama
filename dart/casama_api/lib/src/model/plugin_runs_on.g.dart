// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plugin_runs_on.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PluginRunsOnCWProxy {
  PluginRunsOn deviceId(String deviceId);

  PluginRunsOn deviceName(String deviceName);

  PluginRunsOn ownerUserId(String ownerUserId);

  PluginRunsOn online(bool online);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PluginRunsOn(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PluginRunsOn(...).copyWith(id: 12, name: "My name")
  /// ```
  PluginRunsOn call({
    String deviceId,
    String deviceName,
    String ownerUserId,
    bool online,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfPluginRunsOn.copyWith(...)` or call `instanceOfPluginRunsOn.copyWith.fieldName(value)` for a single field.
class _$PluginRunsOnCWProxyImpl implements _$PluginRunsOnCWProxy {
  const _$PluginRunsOnCWProxyImpl(this._value);

  final PluginRunsOn _value;

  @override
  PluginRunsOn deviceId(String deviceId) => call(deviceId: deviceId);

  @override
  PluginRunsOn deviceName(String deviceName) => call(deviceName: deviceName);

  @override
  PluginRunsOn ownerUserId(String ownerUserId) =>
      call(ownerUserId: ownerUserId);

  @override
  PluginRunsOn online(bool online) => call(online: online);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PluginRunsOn(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PluginRunsOn(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  PluginRunsOn call({
    Object? deviceId = const $CopyWithPlaceholder(),
    Object? deviceName = const $CopyWithPlaceholder(),
    Object? ownerUserId = const $CopyWithPlaceholder(),
    Object? online = const $CopyWithPlaceholder(),
  }) {
    return PluginRunsOn(
      deviceId: deviceId == const $CopyWithPlaceholder() || deviceId == null
          ? _value.deviceId
          // ignore: cast_nullable_to_non_nullable
          : deviceId as String,
      deviceName:
          deviceName == const $CopyWithPlaceholder() || deviceName == null
          ? _value.deviceName
          // ignore: cast_nullable_to_non_nullable
          : deviceName as String,
      ownerUserId:
          ownerUserId == const $CopyWithPlaceholder() || ownerUserId == null
          ? _value.ownerUserId
          // ignore: cast_nullable_to_non_nullable
          : ownerUserId as String,
      online: online == const $CopyWithPlaceholder() || online == null
          ? _value.online
          // ignore: cast_nullable_to_non_nullable
          : online as bool,
    );
  }
}

extension $PluginRunsOnCopyWith on PluginRunsOn {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfPluginRunsOn.copyWith(...)` or `instanceOfPluginRunsOn.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PluginRunsOnCWProxy get copyWith => _$PluginRunsOnCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PluginRunsOn _$PluginRunsOnFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'PluginRunsOn',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'device_id',
            'device_name',
            'owner_user_id',
            'online',
          ],
        );
        final val = PluginRunsOn(
          deviceId: $checkedConvert('device_id', (v) => v as String),
          deviceName: $checkedConvert('device_name', (v) => v as String),
          ownerUserId: $checkedConvert('owner_user_id', (v) => v as String),
          online: $checkedConvert('online', (v) => v as bool),
        );
        return val;
      },
      fieldKeyMap: const {
        'deviceId': 'device_id',
        'deviceName': 'device_name',
        'ownerUserId': 'owner_user_id',
      },
    );

Map<String, dynamic> _$PluginRunsOnToJson(PluginRunsOn instance) =>
    <String, dynamic>{
      'device_id': instance.deviceId,
      'device_name': instance.deviceName,
      'owner_user_id': instance.ownerUserId,
      'online': instance.online,
    };
