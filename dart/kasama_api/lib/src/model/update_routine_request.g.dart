// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_routine_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$UpdateRoutineRequestCWProxy {
  UpdateRoutineRequest name(String? name);

  UpdateRoutineRequest instructions(String? instructions);

  UpdateRoutineRequest scheduleCron(String? scheduleCron);

  UpdateRoutineRequest runAt(DateTime? runAt);

  UpdateRoutineRequest timezone(String? timezone);

  UpdateRoutineRequest notify(bool? notify);

  UpdateRoutineRequest enabled(bool? enabled);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `UpdateRoutineRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// UpdateRoutineRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  UpdateRoutineRequest call({
    String? name,
    String? instructions,
    String? scheduleCron,
    DateTime? runAt,
    String? timezone,
    bool? notify,
    bool? enabled,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfUpdateRoutineRequest.copyWith(...)` or call `instanceOfUpdateRoutineRequest.copyWith.fieldName(value)` for a single field.
class _$UpdateRoutineRequestCWProxyImpl
    implements _$UpdateRoutineRequestCWProxy {
  const _$UpdateRoutineRequestCWProxyImpl(this._value);

  final UpdateRoutineRequest _value;

  @override
  UpdateRoutineRequest name(String? name) => call(name: name);

  @override
  UpdateRoutineRequest instructions(String? instructions) =>
      call(instructions: instructions);

  @override
  UpdateRoutineRequest scheduleCron(String? scheduleCron) =>
      call(scheduleCron: scheduleCron);

  @override
  UpdateRoutineRequest runAt(DateTime? runAt) => call(runAt: runAt);

  @override
  UpdateRoutineRequest timezone(String? timezone) => call(timezone: timezone);

  @override
  UpdateRoutineRequest notify(bool? notify) => call(notify: notify);

  @override
  UpdateRoutineRequest enabled(bool? enabled) => call(enabled: enabled);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `UpdateRoutineRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// UpdateRoutineRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  UpdateRoutineRequest call({
    Object? name = const $CopyWithPlaceholder(),
    Object? instructions = const $CopyWithPlaceholder(),
    Object? scheduleCron = const $CopyWithPlaceholder(),
    Object? runAt = const $CopyWithPlaceholder(),
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
      runAt: runAt == const $CopyWithPlaceholder()
          ? _value.runAt
          // ignore: cast_nullable_to_non_nullable
          : runAt as DateTime?,
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
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfUpdateRoutineRequest.copyWith(...)` or `instanceOfUpdateRoutineRequest.copyWith.fieldName(...)`.
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
    runAt: $checkedConvert(
      'run_at',
      (v) => v == null ? null : DateTime.parse(v as String),
    ),
    timezone: $checkedConvert('timezone', (v) => v as String?),
    notify: $checkedConvert('notify', (v) => v as bool?),
    enabled: $checkedConvert('enabled', (v) => v as bool?),
  );
  return val;
}, fieldKeyMap: const {'scheduleCron': 'schedule_cron', 'runAt': 'run_at'});

Map<String, dynamic> _$UpdateRoutineRequestToJson(
  UpdateRoutineRequest instance,
) => <String, dynamic>{
  'name': ?instance.name,
  'instructions': ?instance.instructions,
  'schedule_cron': ?instance.scheduleCron,
  'run_at': ?instance.runAt?.toIso8601String(),
  'timezone': ?instance.timezone,
  'notify': ?instance.notify,
  'enabled': ?instance.enabled,
};
