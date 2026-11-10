// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_trigger_config.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$DeviceTriggerConfigCWProxy {
  DeviceTriggerConfig event(DeviceTriggerConfigEventEnum event);

  DeviceTriggerConfig place(String? place);

  DeviceTriggerConfig app(String? app);

  DeviceTriggerConfig minutesBefore(int? minutesBefore);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DeviceTriggerConfig(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DeviceTriggerConfig(...).copyWith(id: 12, name: "My name")
  /// ```
  DeviceTriggerConfig call({
    DeviceTriggerConfigEventEnum event,
    String? place,
    String? app,
    int? minutesBefore,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfDeviceTriggerConfig.copyWith(...)` or call `instanceOfDeviceTriggerConfig.copyWith.fieldName(value)` for a single field.
class _$DeviceTriggerConfigCWProxyImpl implements _$DeviceTriggerConfigCWProxy {
  const _$DeviceTriggerConfigCWProxyImpl(this._value);

  final DeviceTriggerConfig _value;

  @override
  DeviceTriggerConfig event(DeviceTriggerConfigEventEnum event) =>
      call(event: event);

  @override
  DeviceTriggerConfig place(String? place) => call(place: place);

  @override
  DeviceTriggerConfig app(String? app) => call(app: app);

  @override
  DeviceTriggerConfig minutesBefore(int? minutesBefore) =>
      call(minutesBefore: minutesBefore);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DeviceTriggerConfig(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DeviceTriggerConfig(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  DeviceTriggerConfig call({
    Object? event = const $CopyWithPlaceholder(),
    Object? place = const $CopyWithPlaceholder(),
    Object? app = const $CopyWithPlaceholder(),
    Object? minutesBefore = const $CopyWithPlaceholder(),
  }) {
    return DeviceTriggerConfig(
      event: event == const $CopyWithPlaceholder() || event == null
          ? _value.event
          // ignore: cast_nullable_to_non_nullable
          : event as DeviceTriggerConfigEventEnum,
      place: place == const $CopyWithPlaceholder()
          ? _value.place
          // ignore: cast_nullable_to_non_nullable
          : place as String?,
      app: app == const $CopyWithPlaceholder()
          ? _value.app
          // ignore: cast_nullable_to_non_nullable
          : app as String?,
      minutesBefore: minutesBefore == const $CopyWithPlaceholder()
          ? _value.minutesBefore
          // ignore: cast_nullable_to_non_nullable
          : minutesBefore as int?,
    );
  }
}

extension $DeviceTriggerConfigCopyWith on DeviceTriggerConfig {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfDeviceTriggerConfig.copyWith(...)` or `instanceOfDeviceTriggerConfig.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$DeviceTriggerConfigCWProxy get copyWith =>
      _$DeviceTriggerConfigCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeviceTriggerConfig _$DeviceTriggerConfigFromJson(Map<String, dynamic> json) =>
    $checkedCreate('DeviceTriggerConfig', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['event']);
      final val = DeviceTriggerConfig(
        event: $checkedConvert(
          'event',
          (v) => $enumDecode(_$DeviceTriggerConfigEventEnumEnumMap, v),
        ),
        place: $checkedConvert('place', (v) => v as String?),
        app: $checkedConvert('app', (v) => v as String?),
        minutesBefore: $checkedConvert(
          'minutes_before',
          (v) => (v as num?)?.toInt(),
        ),
      );
      return val;
    }, fieldKeyMap: const {'minutesBefore': 'minutes_before'});

Map<String, dynamic> _$DeviceTriggerConfigToJson(
  DeviceTriggerConfig instance,
) => <String, dynamic>{
  'event': _$DeviceTriggerConfigEventEnumEnumMap[instance.event]!,
  'place': ?instance.place,
  'app': ?instance.app,
  'minutes_before': ?instance.minutesBefore,
};

const _$DeviceTriggerConfigEventEnumEnumMap = {
  DeviceTriggerConfigEventEnum.wake: 'wake',
  DeviceTriggerConfigEventEnum.arrive: 'arrive',
  DeviceTriggerConfigEventEnum.leave: 'leave',
  DeviceTriggerConfigEventEnum.leaveNow: 'leave_now',
  DeviceTriggerConfigEventEnum.workoutEnded: 'workout_ended',
  DeviceTriggerConfigEventEnum.notification: 'notification',
  DeviceTriggerConfigEventEnum.focusOn: 'focus_on',
  DeviceTriggerConfigEventEnum.focusOff: 'focus_off',
};
