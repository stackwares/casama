// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_routine_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$UpdateRoutineRequestCWProxy {
  UpdateRoutineRequest name(String? name);

  UpdateRoutineRequest instructions(String? instructions);

  UpdateRoutineRequest scheduleCron(String? scheduleCron);

  UpdateRoutineRequest timezone(String? timezone);

  UpdateRoutineRequest notify(bool? notify);

  UpdateRoutineRequest enabled(bool? enabled);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `UpdateRoutineRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// UpdateRoutineRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  UpdateRoutineRequest call({
    String? name,
    String? instructions,
    String? scheduleCron,
    String? timezone,
    bool? notify,
    bool? enabled,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfUpdateRoutineRequest.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfUpdateRoutineRequest.copyWith.fieldName(...)`
class _$UpdateRoutineRequestCWProxyImpl
    implements _$UpdateRoutineRequestCWProxy {
  const _$UpdateRoutineRequestCWProxyImpl(this._value);

  final UpdateRoutineRequest _value;

  @override
  UpdateRoutineRequest name(String? name) => this(name: name);

  @override
  UpdateRoutineRequest instructions(String? instructions) =>
      this(instructions: instructions);

  @override
  UpdateRoutineRequest scheduleCron(String? scheduleCron) =>
      this(scheduleCron: scheduleCron);

  @override
  UpdateRoutineRequest timezone(String? timezone) => this(timezone: timezone);

  @override
  UpdateRoutineRequest notify(bool? notify) => this(notify: notify);

  @override
  UpdateRoutineRequest enabled(bool? enabled) => this(enabled: enabled);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `UpdateRoutineRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// UpdateRoutineRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  UpdateRoutineRequest call({
    Object? name = const $CopyWithPlaceholder(),
    Object? instructions = const $CopyWithPlaceholder(),
    Object? scheduleCron = const $CopyWithPlaceholder(),
    Object? timezone = const $CopyWithPlaceholder(),
    Object? notify = const $CopyWithPlaceholder(),
    Object? enabled = const $CopyWithPlaceholder(),
  }) {
    return UpdateRoutineRequest(
      name: name == const $CopyWithPlaceholder()
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String?,
      instructions: instructions == const $CopyWithPlaceholder()
          ? _value.instructions
          // ignore: cast_nullable_to_non_nullable
          : instructions as String?,
      scheduleCron: scheduleCron == const $CopyWithPlaceholder()
          ? _value.scheduleCron
          // ignore: cast_nullable_to_non_nullable
          : scheduleCron as String?,
      timezone: timezone == const $CopyWithPlaceholder()
          ? _value.timezone
          // ignore: cast_nullable_to_non_nullable
          : timezone as String?,
      notify: notify == const $CopyWithPlaceholder()
          ? _value.notify
          // ignore: cast_nullable_to_non_nullable
          : notify as bool?,
      enabled: enabled == const $CopyWithPlaceholder()
          ? _value.enabled
          // ignore: cast_nullable_to_non_nullable
          : enabled as bool?,
    );
  }
}

extension $UpdateRoutineRequestCopyWith on UpdateRoutineRequest {
  /// Returns a callable class that can be used as follows: `instanceOfUpdateRoutineRequest.copyWith(...)` or like so:`instanceOfUpdateRoutineRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$UpdateRoutineRequestCWProxy get copyWith =>
      _$UpdateRoutineRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UpdateRoutineRequest _$UpdateRoutineRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('UpdateRoutineRequest', json, ($checkedConvert) {
  final val = UpdateRoutineRequest(
    name: $checkedConvert('name', (v) => v as String?),
    instructions: $checkedConvert('instructions', (v) => v as String?),
    scheduleCron: $checkedConvert('schedule_cron', (v) => v as String?),
    timezone: $checkedConvert('timezone', (v) => v as String?),
    notify: $checkedConvert('notify', (v) => v as bool?),
    enabled: $checkedConvert('enabled', (v) => v as bool?),
  );
  return val;
}, fieldKeyMap: const {'scheduleCron': 'schedule_cron'});

Map<String, dynamic> _$UpdateRoutineRequestToJson(
  UpdateRoutineRequest instance,
) => <String, dynamic>{
  'name': ?instance.name,
  'instructions': ?instance.instructions,
  'schedule_cron': ?instance.scheduleCron,
  'timezone': ?instance.timezone,
  'notify': ?instance.notify,
  'enabled': ?instance.enabled,
};
