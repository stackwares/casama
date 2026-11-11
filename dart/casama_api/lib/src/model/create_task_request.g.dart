// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_task_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CreateTaskRequestCWProxy {
  CreateTaskRequest orgId(String orgId);

  CreateTaskRequest title(String title);

  CreateTaskRequest detailsMd(String? detailsMd);

  CreateTaskRequest status(TaskStatus? status);

  CreateTaskRequest priority(TaskPriority? priority);

  CreateTaskRequest assigneeBotId(String? assigneeBotId);

  CreateTaskRequest assigneeUserId(String? assigneeUserId);

  CreateTaskRequest dueAt(DateTime? dueAt);

  CreateTaskRequest labels(List<String>? labels);

  CreateTaskRequest reviewRequired(bool? reviewRequired);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CreateTaskRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CreateTaskRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  CreateTaskRequest call({
    String orgId,
    String title,
    String? detailsMd,
    TaskStatus? status,
    TaskPriority? priority,
    String? assigneeBotId,
    String? assigneeUserId,
    DateTime? dueAt,
    List<String>? labels,
    bool? reviewRequired,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfCreateTaskRequest.copyWith(...)` or call `instanceOfCreateTaskRequest.copyWith.fieldName(value)` for a single field.
class _$CreateTaskRequestCWProxyImpl implements _$CreateTaskRequestCWProxy {
  const _$CreateTaskRequestCWProxyImpl(this._value);

  final CreateTaskRequest _value;

  @override
  CreateTaskRequest orgId(String orgId) => call(orgId: orgId);

  @override
  CreateTaskRequest title(String title) => call(title: title);

  @override
  CreateTaskRequest detailsMd(String? detailsMd) => call(detailsMd: detailsMd);

  @override
  CreateTaskRequest status(TaskStatus? status) => call(status: status);

  @override
  CreateTaskRequest priority(TaskPriority? priority) =>
      call(priority: priority);

  @override
  CreateTaskRequest assigneeBotId(String? assigneeBotId) =>
      call(assigneeBotId: assigneeBotId);

  @override
  CreateTaskRequest assigneeUserId(String? assigneeUserId) =>
      call(assigneeUserId: assigneeUserId);

  @override
  CreateTaskRequest dueAt(DateTime? dueAt) => call(dueAt: dueAt);

  @override
  CreateTaskRequest labels(List<String>? labels) => call(labels: labels);

  @override
  CreateTaskRequest reviewRequired(bool? reviewRequired) =>
      call(reviewRequired: reviewRequired);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CreateTaskRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CreateTaskRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  CreateTaskRequest call({
    Object? orgId = const $CopyWithPlaceholder(),
    Object? title = const $CopyWithPlaceholder(),
    Object? detailsMd = const $CopyWithPlaceholder(),
    Object? status = const $CopyWithPlaceholder(),
    Object? priority = const $CopyWithPlaceholder(),
    Object? assigneeBotId = const $CopyWithPlaceholder(),
    Object? assigneeUserId = const $CopyWithPlaceholder(),
    Object? dueAt = const $CopyWithPlaceholder(),
    Object? labels = const $CopyWithPlaceholder(),
    Object? reviewRequired = const $CopyWithPlaceholder(),
  }) {
    return CreateTaskRequest(
      orgId: orgId == const $CopyWithPlaceholder() || orgId == null
          ? _value.orgId
          // ignore: cast_nullable_to_non_nullable
          : orgId as String,
      title: title == const $CopyWithPlaceholder() || title == null
          ? _value.title
          // ignore: cast_nullable_to_non_nullable
          : title as String,
      detailsMd: detailsMd == const $CopyWithPlaceholder()
          ? _value.detailsMd
          // ignore: cast_nullable_to_non_nullable
          : detailsMd as String?,
      status: status == const $CopyWithPlaceholder()
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as TaskStatus?,
      priority: priority == const $CopyWithPlaceholder()
          ? _value.priority
          // ignore: cast_nullable_to_non_nullable
          : priority as TaskPriority?,
      assigneeBotId: assigneeBotId == const $CopyWithPlaceholder()
          ? _value.assigneeBotId
          // ignore: cast_nullable_to_non_nullable
          : assigneeBotId as String?,
      assigneeUserId: assigneeUserId == const $CopyWithPlaceholder()
          ? _value.assigneeUserId
          // ignore: cast_nullable_to_non_nullable
          : assigneeUserId as String?,
      dueAt: dueAt == const $CopyWithPlaceholder()
          ? _value.dueAt
          // ignore: cast_nullable_to_non_nullable
          : dueAt as DateTime?,
      labels: labels == const $CopyWithPlaceholder()
          ? _value.labels
          // ignore: cast_nullable_to_non_nullable
          : labels as List<String>?,
      reviewRequired: reviewRequired == const $CopyWithPlaceholder()
          ? _value.reviewRequired
          // ignore: cast_nullable_to_non_nullable
          : reviewRequired as bool?,
    );
  }
}

extension $CreateTaskRequestCopyWith on CreateTaskRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfCreateTaskRequest.copyWith(...)` or `instanceOfCreateTaskRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CreateTaskRequestCWProxy get copyWith =>
      _$CreateTaskRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateTaskRequest _$CreateTaskRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'CreateTaskRequest',
  json,
  ($checkedConvert) {
    $checkKeys(json, requiredKeys: const ['org_id', 'title']);
    final val = CreateTaskRequest(
      orgId: $checkedConvert('org_id', (v) => v as String),
      title: $checkedConvert('title', (v) => v as String),
      detailsMd: $checkedConvert('details_md', (v) => v as String?),
      status: $checkedConvert(
        'status',
        (v) => $enumDecodeNullable(_$TaskStatusEnumMap, v),
      ),
      priority: $checkedConvert(
        'priority',
        (v) => $enumDecodeNullable(_$TaskPriorityEnumMap, v),
      ),
      assigneeBotId: $checkedConvert('assignee_bot_id', (v) => v as String?),
      assigneeUserId: $checkedConvert('assignee_user_id', (v) => v as String?),
      dueAt: $checkedConvert(
        'due_at',
        (v) => v == null ? null : DateTime.parse(v as String),
      ),
      labels: $checkedConvert(
        'labels',
        (v) => (v as List<dynamic>?)?.map((e) => e as String).toList(),
      ),
      reviewRequired: $checkedConvert('review_required', (v) => v as bool?),
    );
    return val;
  },
  fieldKeyMap: const {
    'orgId': 'org_id',
    'detailsMd': 'details_md',
    'assigneeBotId': 'assignee_bot_id',
    'assigneeUserId': 'assignee_user_id',
    'dueAt': 'due_at',
    'reviewRequired': 'review_required',
  },
);

Map<String, dynamic> _$CreateTaskRequestToJson(CreateTaskRequest instance) =>
    <String, dynamic>{
      'org_id': instance.orgId,
      'title': instance.title,
      'details_md': ?instance.detailsMd,
      'status': ?_$TaskStatusEnumMap[instance.status],
      'priority': ?_$TaskPriorityEnumMap[instance.priority],
      'assignee_bot_id': ?instance.assigneeBotId,
      'assignee_user_id': ?instance.assigneeUserId,
      'due_at': ?instance.dueAt?.toIso8601String(),
      'labels': ?instance.labels,
      'review_required': ?instance.reviewRequired,
    };

const _$TaskStatusEnumMap = {
  TaskStatus.todo: 'todo',
  TaskStatus.inProgress: 'in_progress',
  TaskStatus.inReview: 'in_review',
  TaskStatus.blocked: 'blocked',
  TaskStatus.done: 'done',
};

const _$TaskPriorityEnumMap = {
  TaskPriority.urgent: 'urgent',
  TaskPriority.high: 'high',
  TaskPriority.medium: 'medium',
  TaskPriority.low: 'low',
  TaskPriority.none: 'none',
};
