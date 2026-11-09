// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_routine_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CreateRoutineRequestCWProxy {
  CreateRoutineRequest botId(String botId);

  CreateRoutineRequest name(String name);

  CreateRoutineRequest instructions(String instructions);

  CreateRoutineRequest trigger(RoutineTrigger? trigger);

  CreateRoutineRequest scheduleCron(String? scheduleCron);

  CreateRoutineRequest timezone(String? timezone);

  CreateRoutineRequest notify(bool? notify);

  CreateRoutineRequest events(List<String>? events);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `CreateRoutineRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// CreateRoutineRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  CreateRoutineRequest call({
    String botId,
    String name,
    String instructions,
    RoutineTrigger? trigger,
    String? scheduleCron,
    String? timezone,
    bool? notify,
    List<String>? events,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfCreateRoutineRequest.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfCreateRoutineRequest.copyWith.fieldName(...)`
class _$CreateRoutineRequestCWProxyImpl
    implements _$CreateRoutineRequestCWProxy {
  const _$CreateRoutineRequestCWProxyImpl(this._value);

  final CreateRoutineRequest _value;

  @override
  CreateRoutineRequest botId(String botId) => this(botId: botId);

  @override
  CreateRoutineRequest name(String name) => this(name: name);

  @override
  CreateRoutineRequest instructions(String instructions) =>
      this(instructions: instructions);

  @override
  CreateRoutineRequest trigger(RoutineTrigger? trigger) =>
      this(trigger: trigger);

  @override
  CreateRoutineRequest scheduleCron(String? scheduleCron) =>
      this(scheduleCron: scheduleCron);

  @override
  CreateRoutineRequest timezone(String? timezone) => this(timezone: timezone);

  @override
  CreateRoutineRequest notify(bool? notify) => this(notify: notify);

  @override
  CreateRoutineRequest events(List<String>? events) => this(events: events);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `CreateRoutineRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// CreateRoutineRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  CreateRoutineRequest call({
    Object? botId = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? instructions = const $CopyWithPlaceholder(),
    Object? trigger = const $CopyWithPlaceholder(),
    Object? scheduleCron = const $CopyWithPlaceholder(),
    Object? timezone = const $CopyWithPlaceholder(),
    Object? notify = const $CopyWithPlaceholder(),
    Object? events = const $CopyWithPlaceholder(),
  }) {
    return CreateRoutineRequest(
      botId: botId == const $CopyWithPlaceholder()
          ? _value.botId
          // ignore: cast_nullable_to_non_nullable
          : botId as String,
      name: name == const $CopyWithPlaceholder()
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      instructions: instructions == const $CopyWithPlaceholder()
          ? _value.instructions
          // ignore: cast_nullable_to_non_nullable
          : instructions as String,
      trigger: trigger == const $CopyWithPlaceholder()
          ? _value.trigger
          // ignore: cast_nullable_to_non_nullable
          : trigger as RoutineTrigger?,
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
      events: events == const $CopyWithPlaceholder()
          ? _value.events
          // ignore: cast_nullable_to_non_nullable
          : events as List<String>?,
    );
  }
}

extension $CreateRoutineRequestCopyWith on CreateRoutineRequest {
  /// Returns a callable class that can be used as follows: `instanceOfCreateRoutineRequest.copyWith(...)` or like so:`instanceOfCreateRoutineRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CreateRoutineRequestCWProxy get copyWith =>
      _$CreateRoutineRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateRoutineRequest _$CreateRoutineRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'CreateRoutineRequest',
  json,
  ($checkedConvert) {
    $checkKeys(json, requiredKeys: const ['bot_id', 'name', 'instructions']);
    final val = CreateRoutineRequest(
      botId: $checkedConvert('bot_id', (v) => v as String),
      name: $checkedConvert('name', (v) => v as String),
      instructions: $checkedConvert('instructions', (v) => v as String),
      trigger: $checkedConvert(
        'trigger',
        (v) => $enumDecodeNullable(_$RoutineTriggerEnumMap, v),
      ),
      scheduleCron: $checkedConvert('schedule_cron', (v) => v as String?),
      timezone: $checkedConvert('timezone', (v) => v as String?),
      notify: $checkedConvert('notify', (v) => v as bool?),
      events: $checkedConvert(
        'events',
        (v) => (v as List<dynamic>?)?.map((e) => e as String).toList(),
      ),
    );
    return val;
  },
  fieldKeyMap: const {'botId': 'bot_id', 'scheduleCron': 'schedule_cron'},
);

Map<String, dynamic> _$CreateRoutineRequestToJson(
  CreateRoutineRequest instance,
) => <String, dynamic>{
  'bot_id': instance.botId,
  'name': instance.name,
  'instructions': instance.instructions,
  'trigger': ?_$RoutineTriggerEnumMap[instance.trigger],
  'schedule_cron': ?instance.scheduleCron,
  'timezone': ?instance.timezone,
  'notify': ?instance.notify,
  'events': ?instance.events,
};

const _$RoutineTriggerEnumMap = {
  RoutineTrigger.schedule: 'schedule',
  RoutineTrigger.github: 'github',
  RoutineTrigger.webhook: 'webhook',
};
