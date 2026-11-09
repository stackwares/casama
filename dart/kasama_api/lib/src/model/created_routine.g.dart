// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'created_routine.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CreatedRoutineCWProxy {
  CreatedRoutine id(String id);

  CreatedRoutine botId(String botId);

  CreatedRoutine name(String name);

  CreatedRoutine instructionsMd(String instructionsMd);

  CreatedRoutine scheduleCron(String? scheduleCron);

  CreatedRoutine timezone(String timezone);

  CreatedRoutine trigger(RoutineTrigger trigger);

  CreatedRoutine notify(bool notify);

  CreatedRoutine enabled(bool enabled);

  CreatedRoutine nextRunAt(DateTime? nextRunAt);

  CreatedRoutine lastRunAt(DateTime? lastRunAt);

  CreatedRoutine conversationId(String? conversationId);

  CreatedRoutine createdAt(DateTime createdAt);

  CreatedRoutine webhookUrl(String? webhookUrl);

  CreatedRoutine webhookSecret(String? webhookSecret);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CreatedRoutine(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CreatedRoutine(...).copyWith(id: 12, name: "My name")
  /// ```
  CreatedRoutine call({
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
    String? webhookUrl,
    String? webhookSecret,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfCreatedRoutine.copyWith(...)` or call `instanceOfCreatedRoutine.copyWith.fieldName(value)` for a single field.
class _$CreatedRoutineCWProxyImpl implements _$CreatedRoutineCWProxy {
  const _$CreatedRoutineCWProxyImpl(this._value);

  final CreatedRoutine _value;

  @override
  CreatedRoutine id(String id) => call(id: id);

  @override
  CreatedRoutine botId(String botId) => call(botId: botId);

  @override
  CreatedRoutine name(String name) => call(name: name);

  @override
  CreatedRoutine instructionsMd(String instructionsMd) =>
      call(instructionsMd: instructionsMd);

  @override
  CreatedRoutine scheduleCron(String? scheduleCron) =>
      call(scheduleCron: scheduleCron);

  @override
  CreatedRoutine timezone(String timezone) => call(timezone: timezone);

  @override
  CreatedRoutine trigger(RoutineTrigger trigger) => call(trigger: trigger);

  @override
  CreatedRoutine notify(bool notify) => call(notify: notify);

  @override
  CreatedRoutine enabled(bool enabled) => call(enabled: enabled);

  @override
  CreatedRoutine nextRunAt(DateTime? nextRunAt) => call(nextRunAt: nextRunAt);

  @override
  CreatedRoutine lastRunAt(DateTime? lastRunAt) => call(lastRunAt: lastRunAt);

  @override
  CreatedRoutine conversationId(String? conversationId) =>
      call(conversationId: conversationId);

  @override
  CreatedRoutine createdAt(DateTime createdAt) => call(createdAt: createdAt);

  @override
  CreatedRoutine webhookUrl(String? webhookUrl) => call(webhookUrl: webhookUrl);

  @override
  CreatedRoutine webhookSecret(String? webhookSecret) =>
      call(webhookSecret: webhookSecret);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CreatedRoutine(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CreatedRoutine(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  CreatedRoutine call({
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
    Object? webhookUrl = const $CopyWithPlaceholder(),
    Object? webhookSecret = const $CopyWithPlaceholder(),
  }) {
    return CreatedRoutine(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      botId: botId == const $CopyWithPlaceholder() || botId == null
          ? _value.botId
          // ignore: cast_nullable_to_non_nullable
          : botId as String,
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      instructionsMd:
          instructionsMd == const $CopyWithPlaceholder() ||
              instructionsMd == null
          ? _value.instructionsMd
          // ignore: cast_nullable_to_non_nullable
          : instructionsMd as String,
      scheduleCron: scheduleCron == const $CopyWithPlaceholder()
          ? _value.scheduleCron
          // ignore: cast_nullable_to_non_nullable
          : scheduleCron as String?,
      timezone: timezone == const $CopyWithPlaceholder() || timezone == null
          ? _value.timezone
          // ignore: cast_nullable_to_non_nullable
          : timezone as String,
      trigger: trigger == const $CopyWithPlaceholder() || trigger == null
          ? _value.trigger
          // ignore: cast_nullable_to_non_nullable
          : trigger as RoutineTrigger,
      notify: notify == const $CopyWithPlaceholder() || notify == null
          ? _value.notify
          // ignore: cast_nullable_to_non_nullable
          : notify as bool,
      enabled: enabled == const $CopyWithPlaceholder() || enabled == null
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
      createdAt: createdAt == const $CopyWithPlaceholder() || createdAt == null
          ? _value.createdAt
          // ignore: cast_nullable_to_non_nullable
          : createdAt as DateTime,
      webhookUrl: webhookUrl == const $CopyWithPlaceholder()
          ? _value.webhookUrl
          // ignore: cast_nullable_to_non_nullable
          : webhookUrl as String?,
      webhookSecret: webhookSecret == const $CopyWithPlaceholder()
          ? _value.webhookSecret
          // ignore: cast_nullable_to_non_nullable
          : webhookSecret as String?,
    );
  }
}

extension $CreatedRoutineCopyWith on CreatedRoutine {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfCreatedRoutine.copyWith(...)` or `instanceOfCreatedRoutine.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CreatedRoutineCWProxy get copyWith => _$CreatedRoutineCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreatedRoutine _$CreatedRoutineFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'CreatedRoutine',
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
    final val = CreatedRoutine(
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
      webhookUrl: $checkedConvert('webhook_url', (v) => v as String?),
      webhookSecret: $checkedConvert('webhook_secret', (v) => v as String?),
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
    'webhookUrl': 'webhook_url',
    'webhookSecret': 'webhook_secret',
  },
);

Map<String, dynamic> _$CreatedRoutineToJson(CreatedRoutine instance) =>
    <String, dynamic>{
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
      'webhook_url': ?instance.webhookUrl,
      'webhook_secret': ?instance.webhookSecret,
    };

const _$RoutineTriggerEnumMap = {
  RoutineTrigger.schedule: 'schedule',
  RoutineTrigger.once: 'once',
  RoutineTrigger.github: 'github',
  RoutineTrigger.webhook: 'webhook',
};
