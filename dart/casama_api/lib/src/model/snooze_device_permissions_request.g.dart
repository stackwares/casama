// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'snooze_device_permissions_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SnoozeDevicePermissionsRequestCWProxy {
  SnoozeDevicePermissionsRequest botId(String botId);

  SnoozeDevicePermissionsRequest permissions(List<String> permissions);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SnoozeDevicePermissionsRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SnoozeDevicePermissionsRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  SnoozeDevicePermissionsRequest call({String botId, List<String> permissions});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfSnoozeDevicePermissionsRequest.copyWith(...)` or call `instanceOfSnoozeDevicePermissionsRequest.copyWith.fieldName(value)` for a single field.
class _$SnoozeDevicePermissionsRequestCWProxyImpl
    implements _$SnoozeDevicePermissionsRequestCWProxy {
  const _$SnoozeDevicePermissionsRequestCWProxyImpl(this._value);

  final SnoozeDevicePermissionsRequest _value;

  @override
  SnoozeDevicePermissionsRequest botId(String botId) => call(botId: botId);

  @override
  SnoozeDevicePermissionsRequest permissions(List<String> permissions) =>
      call(permissions: permissions);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SnoozeDevicePermissionsRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SnoozeDevicePermissionsRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  SnoozeDevicePermissionsRequest call({
    Object? botId = const $CopyWithPlaceholder(),
    Object? permissions = const $CopyWithPlaceholder(),
  }) {
    return SnoozeDevicePermissionsRequest(
      botId: botId == const $CopyWithPlaceholder() || botId == null
          ? _value.botId
          // ignore: cast_nullable_to_non_nullable
          : botId as String,
      permissions:
          permissions == const $CopyWithPlaceholder() || permissions == null
          ? _value.permissions
          // ignore: cast_nullable_to_non_nullable
          : permissions as List<String>,
    );
  }
}

extension $SnoozeDevicePermissionsRequestCopyWith
    on SnoozeDevicePermissionsRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfSnoozeDevicePermissionsRequest.copyWith(...)` or `instanceOfSnoozeDevicePermissionsRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SnoozeDevicePermissionsRequestCWProxy get copyWith =>
      _$SnoozeDevicePermissionsRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SnoozeDevicePermissionsRequest _$SnoozeDevicePermissionsRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('SnoozeDevicePermissionsRequest', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['bot_id', 'permissions']);
  final val = SnoozeDevicePermissionsRequest(
    botId: $checkedConvert('bot_id', (v) => v as String),
    permissions: $checkedConvert(
      'permissions',
      (v) => (v as List<dynamic>).map((e) => e as String).toList(),
    ),
  );
  return val;
}, fieldKeyMap: const {'botId': 'bot_id'});

Map<String, dynamic> _$SnoozeDevicePermissionsRequestToJson(
  SnoozeDevicePermissionsRequest instance,
) => <String, dynamic>{
  'bot_id': instance.botId,
  'permissions': instance.permissions,
};
