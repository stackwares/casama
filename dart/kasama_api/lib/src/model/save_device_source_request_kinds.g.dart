// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'save_device_source_request_kinds.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SaveDeviceSourceRequestKindsCWProxy {
  SaveDeviceSourceRequestKinds calendar(DeviceKindSettings? calendar);

  SaveDeviceSourceRequestKinds reminders(DeviceKindSettings? reminders);

  SaveDeviceSourceRequestKinds contacts(DeviceKindSettings? contacts);

  SaveDeviceSourceRequestKinds places(DeviceKindSettings? places);

  SaveDeviceSourceRequestKinds photos(DeviceKindSettings? photos);

  SaveDeviceSourceRequestKinds health(DeviceKindSettings? health);

  SaveDeviceSourceRequestKinds notifications(DeviceKindSettings? notifications);

  SaveDeviceSourceRequestKinds activity(DeviceKindSettings? activity);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SaveDeviceSourceRequestKinds(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SaveDeviceSourceRequestKinds(...).copyWith(id: 12, name: "My name")
  /// ```
  SaveDeviceSourceRequestKinds call({
    DeviceKindSettings? calendar,
    DeviceKindSettings? reminders,
    DeviceKindSettings? contacts,
    DeviceKindSettings? places,
    DeviceKindSettings? photos,
    DeviceKindSettings? health,
    DeviceKindSettings? notifications,
    DeviceKindSettings? activity,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfSaveDeviceSourceRequestKinds.copyWith(...)` or call `instanceOfSaveDeviceSourceRequestKinds.copyWith.fieldName(value)` for a single field.
class _$SaveDeviceSourceRequestKindsCWProxyImpl
    implements _$SaveDeviceSourceRequestKindsCWProxy {
  const _$SaveDeviceSourceRequestKindsCWProxyImpl(this._value);

  final SaveDeviceSourceRequestKinds _value;

  @override
  SaveDeviceSourceRequestKinds calendar(DeviceKindSettings? calendar) =>
      call(calendar: calendar);

  @override
  SaveDeviceSourceRequestKinds reminders(DeviceKindSettings? reminders) =>
      call(reminders: reminders);

  @override
  SaveDeviceSourceRequestKinds contacts(DeviceKindSettings? contacts) =>
      call(contacts: contacts);

  @override
  SaveDeviceSourceRequestKinds places(DeviceKindSettings? places) =>
      call(places: places);

  @override
  SaveDeviceSourceRequestKinds photos(DeviceKindSettings? photos) =>
      call(photos: photos);

  @override
  SaveDeviceSourceRequestKinds health(DeviceKindSettings? health) =>
      call(health: health);

  @override
  SaveDeviceSourceRequestKinds notifications(
    DeviceKindSettings? notifications,
  ) => call(notifications: notifications);

  @override
  SaveDeviceSourceRequestKinds activity(DeviceKindSettings? activity) =>
      call(activity: activity);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SaveDeviceSourceRequestKinds(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SaveDeviceSourceRequestKinds(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  SaveDeviceSourceRequestKinds call({
    Object? calendar = const $CopyWithPlaceholder(),
    Object? reminders = const $CopyWithPlaceholder(),
    Object? contacts = const $CopyWithPlaceholder(),
    Object? places = const $CopyWithPlaceholder(),
    Object? photos = const $CopyWithPlaceholder(),
    Object? health = const $CopyWithPlaceholder(),
    Object? notifications = const $CopyWithPlaceholder(),
    Object? activity = const $CopyWithPlaceholder(),
  }) {
    return SaveDeviceSourceRequestKinds(
      calendar: calendar == const $CopyWithPlaceholder()
          ? _value.calendar
          // ignore: cast_nullable_to_non_nullable
          : calendar as DeviceKindSettings?,
      reminders: reminders == const $CopyWithPlaceholder()
          ? _value.reminders
          // ignore: cast_nullable_to_non_nullable
          : reminders as DeviceKindSettings?,
      contacts: contacts == const $CopyWithPlaceholder()
          ? _value.contacts
          // ignore: cast_nullable_to_non_nullable
          : contacts as DeviceKindSettings?,
      places: places == const $CopyWithPlaceholder()
          ? _value.places
          // ignore: cast_nullable_to_non_nullable
          : places as DeviceKindSettings?,
      photos: photos == const $CopyWithPlaceholder()
          ? _value.photos
          // ignore: cast_nullable_to_non_nullable
          : photos as DeviceKindSettings?,
      health: health == const $CopyWithPlaceholder()
          ? _value.health
          // ignore: cast_nullable_to_non_nullable
          : health as DeviceKindSettings?,
      notifications: notifications == const $CopyWithPlaceholder()
          ? _value.notifications
          // ignore: cast_nullable_to_non_nullable
          : notifications as DeviceKindSettings?,
      activity: activity == const $CopyWithPlaceholder()
          ? _value.activity
          // ignore: cast_nullable_to_non_nullable
          : activity as DeviceKindSettings?,
    );
  }
}

extension $SaveDeviceSourceRequestKindsCopyWith
    on SaveDeviceSourceRequestKinds {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfSaveDeviceSourceRequestKinds.copyWith(...)` or `instanceOfSaveDeviceSourceRequestKinds.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SaveDeviceSourceRequestKindsCWProxy get copyWith =>
      _$SaveDeviceSourceRequestKindsCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SaveDeviceSourceRequestKinds _$SaveDeviceSourceRequestKindsFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('SaveDeviceSourceRequestKinds', json, ($checkedConvert) {
  final val = SaveDeviceSourceRequestKinds(
    calendar: $checkedConvert(
      'calendar',
      (v) => v == null
          ? null
          : DeviceKindSettings.fromJson(v as Map<String, dynamic>),
    ),
    reminders: $checkedConvert(
      'reminders',
      (v) => v == null
          ? null
          : DeviceKindSettings.fromJson(v as Map<String, dynamic>),
    ),
    contacts: $checkedConvert(
      'contacts',
      (v) => v == null
          ? null
          : DeviceKindSettings.fromJson(v as Map<String, dynamic>),
    ),
    places: $checkedConvert(
      'places',
      (v) => v == null
          ? null
          : DeviceKindSettings.fromJson(v as Map<String, dynamic>),
    ),
    photos: $checkedConvert(
      'photos',
      (v) => v == null
          ? null
          : DeviceKindSettings.fromJson(v as Map<String, dynamic>),
    ),
    health: $checkedConvert(
      'health',
      (v) => v == null
          ? null
          : DeviceKindSettings.fromJson(v as Map<String, dynamic>),
    ),
    notifications: $checkedConvert(
      'notifications',
      (v) => v == null
          ? null
          : DeviceKindSettings.fromJson(v as Map<String, dynamic>),
    ),
    activity: $checkedConvert(
      'activity',
      (v) => v == null
          ? null
          : DeviceKindSettings.fromJson(v as Map<String, dynamic>),
    ),
  );
  return val;
});

Map<String, dynamic> _$SaveDeviceSourceRequestKindsToJson(
  SaveDeviceSourceRequestKinds instance,
) => <String, dynamic>{
  'calendar': ?instance.calendar?.toJson(),
  'reminders': ?instance.reminders?.toJson(),
  'contacts': ?instance.contacts?.toJson(),
  'places': ?instance.places?.toJson(),
  'photos': ?instance.photos?.toJson(),
  'health': ?instance.health?.toJson(),
  'notifications': ?instance.notifications?.toJson(),
  'activity': ?instance.activity?.toJson(),
};
