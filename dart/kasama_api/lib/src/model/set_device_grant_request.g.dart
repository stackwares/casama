// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'set_device_grant_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SetDeviceGrantRequestCWProxy {
  SetDeviceGrantRequest botId(String botId);

  SetDeviceGrantRequest kind(DeviceKind kind);

  SetDeviceGrantRequest allowed(bool allowed);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SetDeviceGrantRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SetDeviceGrantRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  SetDeviceGrantRequest call({String botId, DeviceKind kind, bool allowed});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfSetDeviceGrantRequest.copyWith(...)` or call `instanceOfSetDeviceGrantRequest.copyWith.fieldName(value)` for a single field.
class _$SetDeviceGrantRequestCWProxyImpl
    implements _$SetDeviceGrantRequestCWProxy {
  const _$SetDeviceGrantRequestCWProxyImpl(this._value);

  final SetDeviceGrantRequest _value;

  @override
  SetDeviceGrantRequest botId(String botId) => call(botId: botId);

  @override
  SetDeviceGrantRequest kind(DeviceKind kind) => call(kind: kind);

  @override
  SetDeviceGrantRequest allowed(bool allowed) => call(allowed: allowed);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SetDeviceGrantRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SetDeviceGrantRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  SetDeviceGrantRequest call({
    Object? botId = const $CopyWithPlaceholder(),
    Object? kind = const $CopyWithPlaceholder(),
    Object? allowed = const $CopyWithPlaceholder(),
  }) {
    return SetDeviceGrantRequest(
      botId: botId == const $CopyWithPlaceholder() || botId == null
          ? _value.botId
          // ignore: cast_nullable_to_non_nullable
          : botId as String,
      kind: kind == const $CopyWithPlaceholder() || kind == null
          ? _value.kind
          // ignore: cast_nullable_to_non_nullable
          : kind as DeviceKind,
      allowed: allowed == const $CopyWithPlaceholder() || allowed == null
          ? _value.allowed
          // ignore: cast_nullable_to_non_nullable
          : allowed as bool,
    );
  }
}

extension $SetDeviceGrantRequestCopyWith on SetDeviceGrantRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfSetDeviceGrantRequest.copyWith(...)` or `instanceOfSetDeviceGrantRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SetDeviceGrantRequestCWProxy get copyWith =>
      _$SetDeviceGrantRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SetDeviceGrantRequest _$SetDeviceGrantRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('SetDeviceGrantRequest', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['bot_id', 'kind', 'allowed']);
  final val = SetDeviceGrantRequest(
    botId: $checkedConvert('bot_id', (v) => v as String),
    kind: $checkedConvert('kind', (v) => $enumDecode(_$DeviceKindEnumMap, v)),
    allowed: $checkedConvert('allowed', (v) => v as bool),
  );
  return val;
}, fieldKeyMap: const {'botId': 'bot_id'});

Map<String, dynamic> _$SetDeviceGrantRequestToJson(
  SetDeviceGrantRequest instance,
) => <String, dynamic>{
  'bot_id': instance.botId,
  'kind': _$DeviceKindEnumMap[instance.kind]!,
  'allowed': instance.allowed,
};

const _$DeviceKindEnumMap = {
  DeviceKind.calendar: 'calendar',
  DeviceKind.reminders: 'reminders',
  DeviceKind.contacts: 'contacts',
  DeviceKind.places: 'places',
  DeviceKind.photos: 'photos',
  DeviceKind.health: 'health',
  DeviceKind.notifications: 'notifications',
  DeviceKind.activity: 'activity',
};
