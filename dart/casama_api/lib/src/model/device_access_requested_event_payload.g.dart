// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_access_requested_event_payload.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$DeviceAccessRequestedEventPayloadCWProxy {
  DeviceAccessRequestedEventPayload kind(
    DeviceAccessRequestedEventPayloadKindEnum kind,
  );

  DeviceAccessRequestedEventPayload reason(String reason);

  DeviceAccessRequestedEventPayload botId(String botId);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DeviceAccessRequestedEventPayload(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DeviceAccessRequestedEventPayload(...).copyWith(id: 12, name: "My name")
  /// ```
  DeviceAccessRequestedEventPayload call({
    DeviceAccessRequestedEventPayloadKindEnum kind,
    String reason,
    String botId,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfDeviceAccessRequestedEventPayload.copyWith(...)` or call `instanceOfDeviceAccessRequestedEventPayload.copyWith.fieldName(value)` for a single field.
class _$DeviceAccessRequestedEventPayloadCWProxyImpl
    implements _$DeviceAccessRequestedEventPayloadCWProxy {
  const _$DeviceAccessRequestedEventPayloadCWProxyImpl(this._value);

  final DeviceAccessRequestedEventPayload _value;

  @override
  DeviceAccessRequestedEventPayload kind(
    DeviceAccessRequestedEventPayloadKindEnum kind,
  ) => call(kind: kind);

  @override
  DeviceAccessRequestedEventPayload reason(String reason) =>
      call(reason: reason);

  @override
  DeviceAccessRequestedEventPayload botId(String botId) => call(botId: botId);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DeviceAccessRequestedEventPayload(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DeviceAccessRequestedEventPayload(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  DeviceAccessRequestedEventPayload call({
    Object? kind = const $CopyWithPlaceholder(),
    Object? reason = const $CopyWithPlaceholder(),
    Object? botId = const $CopyWithPlaceholder(),
  }) {
    return DeviceAccessRequestedEventPayload(
      kind: kind == const $CopyWithPlaceholder() || kind == null
          ? _value.kind
          // ignore: cast_nullable_to_non_nullable
          : kind as DeviceAccessRequestedEventPayloadKindEnum,
      reason: reason == const $CopyWithPlaceholder() || reason == null
          ? _value.reason
          // ignore: cast_nullable_to_non_nullable
          : reason as String,
      botId: botId == const $CopyWithPlaceholder() || botId == null
          ? _value.botId
          // ignore: cast_nullable_to_non_nullable
          : botId as String,
    );
  }
}

extension $DeviceAccessRequestedEventPayloadCopyWith
    on DeviceAccessRequestedEventPayload {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfDeviceAccessRequestedEventPayload.copyWith(...)` or `instanceOfDeviceAccessRequestedEventPayload.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$DeviceAccessRequestedEventPayloadCWProxy get copyWith =>
      _$DeviceAccessRequestedEventPayloadCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeviceAccessRequestedEventPayload _$DeviceAccessRequestedEventPayloadFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('DeviceAccessRequestedEventPayload', json, (
  $checkedConvert,
) {
  $checkKeys(json, requiredKeys: const ['kind', 'reason', 'bot_id']);
  final val = DeviceAccessRequestedEventPayload(
    kind: $checkedConvert(
      'kind',
      (v) => $enumDecode(_$DeviceAccessRequestedEventPayloadKindEnumEnumMap, v),
    ),
    reason: $checkedConvert('reason', (v) => v as String),
    botId: $checkedConvert('bot_id', (v) => v as String),
  );
  return val;
}, fieldKeyMap: const {'botId': 'bot_id'});

Map<String, dynamic> _$DeviceAccessRequestedEventPayloadToJson(
  DeviceAccessRequestedEventPayload instance,
) => <String, dynamic>{
  'kind': _$DeviceAccessRequestedEventPayloadKindEnumEnumMap[instance.kind]!,
  'reason': instance.reason,
  'bot_id': instance.botId,
};

const _$DeviceAccessRequestedEventPayloadKindEnumEnumMap = {
  DeviceAccessRequestedEventPayloadKindEnum.calendar: 'calendar',
  DeviceAccessRequestedEventPayloadKindEnum.reminders: 'reminders',
  DeviceAccessRequestedEventPayloadKindEnum.contacts: 'contacts',
  DeviceAccessRequestedEventPayloadKindEnum.places: 'places',
  DeviceAccessRequestedEventPayloadKindEnum.photos: 'photos',
  DeviceAccessRequestedEventPayloadKindEnum.health: 'health',
  DeviceAccessRequestedEventPayloadKindEnum.notifications: 'notifications',
  DeviceAccessRequestedEventPayloadKindEnum.activity: 'activity',
};
