// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_grant.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$DeviceGrantCWProxy {
  DeviceGrant botId(String botId);

  DeviceGrant botName(String botName);

  DeviceGrant kind(DeviceKind kind);

  DeviceGrant createdAt(DateTime createdAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DeviceGrant(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DeviceGrant(...).copyWith(id: 12, name: "My name")
  /// ```
  DeviceGrant call({
    String botId,
    String botName,
    DeviceKind kind,
    DateTime createdAt,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfDeviceGrant.copyWith(...)` or call `instanceOfDeviceGrant.copyWith.fieldName(value)` for a single field.
class _$DeviceGrantCWProxyImpl implements _$DeviceGrantCWProxy {
  const _$DeviceGrantCWProxyImpl(this._value);

  final DeviceGrant _value;

  @override
  DeviceGrant botId(String botId) => call(botId: botId);

  @override
  DeviceGrant botName(String botName) => call(botName: botName);

  @override
  DeviceGrant kind(DeviceKind kind) => call(kind: kind);

  @override
  DeviceGrant createdAt(DateTime createdAt) => call(createdAt: createdAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DeviceGrant(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DeviceGrant(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  DeviceGrant call({
    Object? botId = const $CopyWithPlaceholder(),
    Object? botName = const $CopyWithPlaceholder(),
    Object? kind = const $CopyWithPlaceholder(),
    Object? createdAt = const $CopyWithPlaceholder(),
  }) {
    return DeviceGrant(
      botId: botId == const $CopyWithPlaceholder() || botId == null
          ? _value.botId
          // ignore: cast_nullable_to_non_nullable
          : botId as String,
      botName: botName == const $CopyWithPlaceholder() || botName == null
          ? _value.botName
          // ignore: cast_nullable_to_non_nullable
          : botName as String,
      kind: kind == const $CopyWithPlaceholder() || kind == null
          ? _value.kind
          // ignore: cast_nullable_to_non_nullable
          : kind as DeviceKind,
      createdAt: createdAt == const $CopyWithPlaceholder() || createdAt == null
          ? _value.createdAt
          // ignore: cast_nullable_to_non_nullable
          : createdAt as DateTime,
    );
  }
}

extension $DeviceGrantCopyWith on DeviceGrant {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfDeviceGrant.copyWith(...)` or `instanceOfDeviceGrant.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$DeviceGrantCWProxy get copyWith => _$DeviceGrantCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeviceGrant _$DeviceGrantFromJson(Map<String, dynamic> json) => $checkedCreate(
  'DeviceGrant',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const ['bot_id', 'bot_name', 'kind', 'created_at'],
    );
    final val = DeviceGrant(
      botId: $checkedConvert('bot_id', (v) => v as String),
      botName: $checkedConvert('bot_name', (v) => v as String),
      kind: $checkedConvert('kind', (v) => $enumDecode(_$DeviceKindEnumMap, v)),
      createdAt: $checkedConvert(
        'created_at',
        (v) => DateTime.parse(v as String),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'botId': 'bot_id',
    'botName': 'bot_name',
    'createdAt': 'created_at',
  },
);

Map<String, dynamic> _$DeviceGrantToJson(DeviceGrant instance) =>
    <String, dynamic>{
      'bot_id': instance.botId,
      'bot_name': instance.botName,
      'kind': _$DeviceKindEnumMap[instance.kind]!,
      'created_at': instance.createdAt.toIso8601String(),
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
