// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project_run.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ProjectRunCWProxy {
  ProjectRun id(String id);

  ProjectRun botId(String botId);

  ProjectRun trigger(String trigger);

  ProjectRun status(String status);

  ProjectRun costUsd(num costUsd);

  ProjectRun createdAt(DateTime createdAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ProjectRun(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ProjectRun(...).copyWith(id: 12, name: "My name")
  /// ```
  ProjectRun call({
    String id,
    String botId,
    String trigger,
    String status,
    num costUsd,
    DateTime createdAt,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfProjectRun.copyWith(...)` or call `instanceOfProjectRun.copyWith.fieldName(value)` for a single field.
class _$ProjectRunCWProxyImpl implements _$ProjectRunCWProxy {
  const _$ProjectRunCWProxyImpl(this._value);

  final ProjectRun _value;

  @override
  ProjectRun id(String id) => call(id: id);

  @override
  ProjectRun botId(String botId) => call(botId: botId);

  @override
  ProjectRun trigger(String trigger) => call(trigger: trigger);

  @override
  ProjectRun status(String status) => call(status: status);

  @override
  ProjectRun costUsd(num costUsd) => call(costUsd: costUsd);

  @override
  ProjectRun createdAt(DateTime createdAt) => call(createdAt: createdAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ProjectRun(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ProjectRun(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ProjectRun call({
    Object? id = const $CopyWithPlaceholder(),
    Object? botId = const $CopyWithPlaceholder(),
    Object? trigger = const $CopyWithPlaceholder(),
    Object? status = const $CopyWithPlaceholder(),
    Object? costUsd = const $CopyWithPlaceholder(),
    Object? createdAt = const $CopyWithPlaceholder(),
  }) {
    return ProjectRun(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      botId: botId == const $CopyWithPlaceholder() || botId == null
          ? _value.botId
          // ignore: cast_nullable_to_non_nullable
          : botId as String,
      trigger: trigger == const $CopyWithPlaceholder() || trigger == null
          ? _value.trigger
          // ignore: cast_nullable_to_non_nullable
          : trigger as String,
      status: status == const $CopyWithPlaceholder() || status == null
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as String,
      costUsd: costUsd == const $CopyWithPlaceholder() || costUsd == null
          ? _value.costUsd
          // ignore: cast_nullable_to_non_nullable
          : costUsd as num,
      createdAt: createdAt == const $CopyWithPlaceholder() || createdAt == null
          ? _value.createdAt
          // ignore: cast_nullable_to_non_nullable
          : createdAt as DateTime,
    );
  }
}

extension $ProjectRunCopyWith on ProjectRun {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfProjectRun.copyWith(...)` or `instanceOfProjectRun.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ProjectRunCWProxy get copyWith => _$ProjectRunCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProjectRun _$ProjectRunFromJson(Map<String, dynamic> json) => $checkedCreate(
  'ProjectRun',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'id',
        'bot_id',
        'trigger',
        'status',
        'cost_usd',
        'created_at',
      ],
    );
    final val = ProjectRun(
      id: $checkedConvert('id', (v) => v as String),
      botId: $checkedConvert('bot_id', (v) => v as String),
      trigger: $checkedConvert('trigger', (v) => v as String),
      status: $checkedConvert('status', (v) => v as String),
      costUsd: $checkedConvert('cost_usd', (v) => v as num),
      createdAt: $checkedConvert(
        'created_at',
        (v) => DateTime.parse(v as String),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'botId': 'bot_id',
    'costUsd': 'cost_usd',
    'createdAt': 'created_at',
  },
);

Map<String, dynamic> _$ProjectRunToJson(ProjectRun instance) =>
    <String, dynamic>{
      'id': instance.id,
      'bot_id': instance.botId,
      'trigger': instance.trigger,
      'status': instance.status,
      'cost_usd': instance.costUsd,
      'created_at': instance.createdAt.toIso8601String(),
    };
