// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'routine.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$RoutineCWProxy {
  Routine id(String id);

  Routine botId(String botId);

  Routine name(String name);

  Routine instructionsMd(String instructionsMd);

  Routine scheduleCron(String? scheduleCron);

  Routine timezone(String timezone);

  Routine trigger(RoutineTrigger trigger);

  Routine notify(bool notify);

  Routine enabled(bool enabled);

  Routine nextRunAt(DateTime? nextRunAt);

  Routine lastRunAt(DateTime? lastRunAt);

  Routine conversationId(String? conversationId);

  Routine createdAt(DateTime createdAt);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Routine(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Routine(...).copyWith(id: 12, name: "My name")
  /// ````
  Routine call({
    String id,
    String botId,
    String name,
    String instructionsMd,
    String? scheduleCron,
    String timezone,
    RoutineTrigger trigger,
    bool notify,
    bool enabled,
    DateTime? nextRunAt,
    DateTime? lastRunAt,
    String? conversationId,
    DateTime createdAt,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfRoutine.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfRoutine.copyWith.fieldName(...)`
class _$RoutineCWProxyImpl implements _$RoutineCWProxy {
  const _$RoutineCWProxyImpl(this._value);

  final Routine _value;

  @override
  Routine id(String id) => this(id: id);

  @override
  Routine botId(String botId) => this(botId: botId);

  @override
  Routine name(String name) => this(name: name);

  @override
  Routine instructionsMd(String instructionsMd) =>
      this(instructionsMd: instructionsMd);

  @override
  Routine scheduleCron(String? scheduleCron) =>
      this(scheduleCron: scheduleCron);

  @override
  Routine timezone(String timezone) => this(timezone: timezone);

  @override
  Routine trigger(RoutineTrigger trigger) => this(trigger: trigger);

  @override
  Routine notify(bool notify) => this(notify: notify);

  @override
  Routine enabled(bool enabled) => this(enabled: enabled);

  @override
  Routine nextRunAt(DateTime? nextRunAt) => this(nextRunAt: nextRunAt);

  @override
  Routine lastRunAt(DateTime? lastRunAt) => this(lastRunAt: lastRunAt);

  @override
  Routine conversationId(String? conversationId) =>
      this(conversationId: conversationId);

  @override
  Routine createdAt(DateTime createdAt) => this(createdAt: createdAt);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Routine(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Routine(...).copyWith(id: 12, name: "My name")
  /// ````
  Routine call({
    Object? id = const $CopyWithPlaceholder(),
    Object? botId = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? instructionsMd = const $CopyWithPlaceholder(),
    Object? scheduleCron = const $CopyWithPlaceholder(),
    Object? timezone = const $CopyWithPlaceholder(),
    Object? trigger = const $CopyWithPlaceholder(),
    Object? notify = const $CopyWithPlaceholder(),
    Object? enabled = const $CopyWithPlaceholder(),
    Object? nextRunAt = const $CopyWithPlaceholder(),
    Object? lastRunAt = const $CopyWithPlaceholder(),
    Object? conversationId = const $CopyWithPlaceholder(),
    Object? createdAt = const $CopyWithPlaceholder(),
  }) {
    return Routine(
      id: id == const $CopyWithPlaceholder()
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      botId: botId == const $CopyWithPlaceholder()
          ? _value.botId
          // ignore: cast_nullable_to_non_nullable
          : botId as String,
      name: name == const $CopyWithPlaceholder()
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      instructionsMd: instructionsMd == const $CopyWithPlaceholder()
          ? _value.instructionsMd
          // ignore: cast_nullable_to_non_nullable
          : instructionsMd as String,
      scheduleCron: scheduleCron == const $CopyWithPlaceholder()
          ? _value.scheduleCron
          // ignore: cast_nullable_to_non_nullable
          : scheduleCron as String?,
      timezone: timezone == const $CopyWithPlaceholder()
          ? _value.timezone
          // ignore: cast_nullable_to_non_nullable
          : timezone as String,
      trigger: trigger == const $CopyWithPlaceholder()
          ? _value.trigger
          // ignore: cast_nullable_to_non_nullable
          : trigger as RoutineTrigger,
      notify: notify == const $CopyWithPlaceholder()
          ? _value.notify
          // ignore: cast_nullable_to_non_nullable
          : notify as bool,
      enabled: enabled == const $CopyWithPlaceholder()
          ? _value.enabled
          // ignore: cast_nullable_to_non_nullable
          : enabled as bool,
      nextRunAt: nextRunAt == const $CopyWithPlaceholder()
          ? _value.nextRunAt
          // ignore: cast_nullable_to_non_nullable
          : nextRunAt as DateTime?,
      lastRunAt: lastRunAt == const $CopyWithPlaceholder()
          ? _value.lastRunAt
          // ignore: cast_nullable_to_non_nullable
          : lastRunAt as DateTime?,
      conversationId: conversationId == const $CopyWithPlaceholder()
          ? _value.conversationId
          // ignore: cast_nullable_to_non_nullable
          : conversationId as String?,
      createdAt: createdAt == const $CopyWithPlaceholder()
          ? _value.createdAt
          // ignore: cast_nullable_to_non_nullable
          : createdAt as DateTime,
    );
  }
}

extension $RoutineCopyWith on Routine {
  /// Returns a callable class that can be used as follows: `instanceOfRoutine.copyWith(...)` or like so:`instanceOfRoutine.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$RoutineCWProxy get copyWith => _$RoutineCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Routine _$RoutineFromJson(Map<String, dynamic> json) => $checkedCreate(
  'Routine',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'id',
        'bot_id',
        'name',
        'instructions_md',
        'schedule_cron',
        'timezone',
        'trigger',
        'notify',
        'enabled',
        'next_run_at',
        'last_run_at',
        'conversation_id',
        'created_at',
      ],
    );
    final val = Routine(
      id: $checkedConvert('id', (v) => v as String),
      botId: $checkedConvert('bot_id', (v) => v as String),
      name: $checkedConvert('name', (v) => v as String),
      instructionsMd: $checkedConvert('instructions_md', (v) => v as String),
      scheduleCron: $checkedConvert('schedule_cron', (v) => v as String?),
      timezone: $checkedConvert('timezone', (v) => v as String),
      trigger: $checkedConvert(
        'trigger',
        (v) => $enumDecode(_$RoutineTriggerEnumMap, v),
      ),
      notify: $checkedConvert('notify', (v) => v as bool),
      enabled: $checkedConvert('enabled', (v) => v as bool),
      nextRunAt: $checkedConvert(
        'next_run_at',
        (v) => v == null ? null : DateTime.parse(v as String),
      ),
      lastRunAt: $checkedConvert(
        'last_run_at',
        (v) => v == null ? null : DateTime.parse(v as String),
      ),
      conversationId: $checkedConvert('conversation_id', (v) => v as String?),
      createdAt: $checkedConvert(
        'created_at',
        (v) => DateTime.parse(v as String),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'botId': 'bot_id',
    'instructionsMd': 'instructions_md',
    'scheduleCron': 'schedule_cron',
    'nextRunAt': 'next_run_at',
    'lastRunAt': 'last_run_at',
    'conversationId': 'conversation_id',
    'createdAt': 'created_at',
  },
);

Map<String, dynamic> _$RoutineToJson(Routine instance) => <String, dynamic>{
  'id': instance.id,
  'bot_id': instance.botId,
  'name': instance.name,
  'instructions_md': instance.instructionsMd,
  'schedule_cron': instance.scheduleCron,
  'timezone': instance.timezone,
  'trigger': _$RoutineTriggerEnumMap[instance.trigger]!,
  'notify': instance.notify,
  'enabled': instance.enabled,
  'next_run_at': instance.nextRunAt?.toIso8601String(),
  'last_run_at': instance.lastRunAt?.toIso8601String(),
  'conversation_id': instance.conversationId,
  'created_at': instance.createdAt.toIso8601String(),
};

const _$RoutineTriggerEnumMap = {
  RoutineTrigger.schedule: 'schedule',
  RoutineTrigger.github: 'github',
  RoutineTrigger.webhook: 'webhook',
};
