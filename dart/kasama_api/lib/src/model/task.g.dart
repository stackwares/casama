// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$TaskCWProxy {
  Task id(String id);

  Task title(String title);

  Task detailsMd(String detailsMd);

  Task status(TaskStatus status);

  Task priority(TaskPriority priority);

  Task assigneeBotId(String? assigneeBotId);

  Task assigneeUserId(String? assigneeUserId);

  Task createdByBotId(String? createdByBotId);

  Task createdByUserId(String? createdByUserId);

  Task resultMd(String? resultMd);

  Task dueAt(DateTime? dueAt);

  Task labels(List<String> labels);

  Task position(num position);

  Task reviewRequired(bool reviewRequired);

  Task conversationId(String? conversationId);

  Task comments(int comments);

  Task updatedAt(DateTime updatedAt);

  Task createdAt(DateTime createdAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `Task(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// Task(...).copyWith(id: 12, name: "My name")
  /// ```
  Task call({
    String id,
    String title,
    String detailsMd,
    TaskStatus status,
    TaskPriority priority,
    String? assigneeBotId,
    String? assigneeUserId,
    String? createdByBotId,
    String? createdByUserId,
    String? resultMd,
    DateTime? dueAt,
    List<String> labels,
    num position,
    bool reviewRequired,
    String? conversationId,
    int comments,
    DateTime updatedAt,
    DateTime createdAt,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfTask.copyWith(...)` or call `instanceOfTask.copyWith.fieldName(value)` for a single field.
class _$TaskCWProxyImpl implements _$TaskCWProxy {
  const _$TaskCWProxyImpl(this._value);

  final Task _value;

  @override
  Task id(String id) => call(id: id);

  @override
  Task title(String title) => call(title: title);

  @override
  Task detailsMd(String detailsMd) => call(detailsMd: detailsMd);

  @override
  Task status(TaskStatus status) => call(status: status);

  @override
  Task priority(TaskPriority priority) => call(priority: priority);

  @override
  Task assigneeBotId(String? assigneeBotId) =>
      call(assigneeBotId: assigneeBotId);

  @override
  Task assigneeUserId(String? assigneeUserId) =>
      call(assigneeUserId: assigneeUserId);

  @override
  Task createdByBotId(String? createdByBotId) =>
      call(createdByBotId: createdByBotId);

  @override
  Task createdByUserId(String? createdByUserId) =>
      call(createdByUserId: createdByUserId);

  @override
  Task resultMd(String? resultMd) => call(resultMd: resultMd);

  @override
  Task dueAt(DateTime? dueAt) => call(dueAt: dueAt);

  @override
  Task labels(List<String> labels) => call(labels: labels);

  @override
  Task position(num position) => call(position: position);

  @override
  Task reviewRequired(bool reviewRequired) =>
      call(reviewRequired: reviewRequired);

  @override
  Task conversationId(String? conversationId) =>
      call(conversationId: conversationId);

  @override
  Task comments(int comments) => call(comments: comments);

  @override
  Task updatedAt(DateTime updatedAt) => call(updatedAt: updatedAt);

  @override
  Task createdAt(DateTime createdAt) => call(createdAt: createdAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `Task(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// Task(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  Task call({
    Object? id = const $CopyWithPlaceholder(),
    Object? title = const $CopyWithPlaceholder(),
    Object? detailsMd = const $CopyWithPlaceholder(),
    Object? status = const $CopyWithPlaceholder(),
    Object? priority = const $CopyWithPlaceholder(),
    Object? assigneeBotId = const $CopyWithPlaceholder(),
    Object? assigneeUserId = const $CopyWithPlaceholder(),
    Object? createdByBotId = const $CopyWithPlaceholder(),
    Object? createdByUserId = const $CopyWithPlaceholder(),
    Object? resultMd = const $CopyWithPlaceholder(),
    Object? dueAt = const $CopyWithPlaceholder(),
    Object? labels = const $CopyWithPlaceholder(),
    Object? position = const $CopyWithPlaceholder(),
    Object? reviewRequired = const $CopyWithPlaceholder(),
    Object? conversationId = const $CopyWithPlaceholder(),
    Object? comments = const $CopyWithPlaceholder(),
    Object? updatedAt = const $CopyWithPlaceholder(),
    Object? createdAt = const $CopyWithPlaceholder(),
  }) {
    return Task(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      title: title == const $CopyWithPlaceholder() || title == null
          ? _value.title
          // ignore: cast_nullable_to_non_nullable
          : title as String,
      detailsMd: detailsMd == const $CopyWithPlaceholder() || detailsMd == null
          ? _value.detailsMd
          // ignore: cast_nullable_to_non_nullable
          : detailsMd as String,
      status: status == const $CopyWithPlaceholder() || status == null
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as TaskStatus,
      priority: priority == const $CopyWithPlaceholder() || priority == null
          ? _value.priority
          // ignore: cast_nullable_to_non_nullable
          : priority as TaskPriority,
      assigneeBotId: assigneeBotId == const $CopyWithPlaceholder()
          ? _value.assigneeBotId
          // ignore: cast_nullable_to_non_nullable
          : assigneeBotId as String?,
      assigneeUserId: assigneeUserId == const $CopyWithPlaceholder()
          ? _value.assigneeUserId
          // ignore: cast_nullable_to_non_nullable
          : assigneeUserId as String?,
      createdByBotId: createdByBotId == const $CopyWithPlaceholder()
          ? _value.createdByBotId
          // ignore: cast_nullable_to_non_nullable
          : createdByBotId as String?,
      createdByUserId: createdByUserId == const $CopyWithPlaceholder()
          ? _value.createdByUserId
          // ignore: cast_nullable_to_non_nullable
          : createdByUserId as String?,
      resultMd: resultMd == const $CopyWithPlaceholder()
          ? _value.resultMd
          // ignore: cast_nullable_to_non_nullable
          : resultMd as String?,
      dueAt: dueAt == const $CopyWithPlaceholder()
          ? _value.dueAt
          // ignore: cast_nullable_to_non_nullable
          : dueAt as DateTime?,
      labels: labels == const $CopyWithPlaceholder() || labels == null
          ? _value.labels
          // ignore: cast_nullable_to_non_nullable
          : labels as List<String>,
      position: position == const $CopyWithPlaceholder() || position == null
          ? _value.position
          // ignore: cast_nullable_to_non_nullable
          : position as num,
      reviewRequired:
          reviewRequired == const $CopyWithPlaceholder() ||
              reviewRequired == null
          ? _value.reviewRequired
          // ignore: cast_nullable_to_non_nullable
          : reviewRequired as bool,
      conversationId: conversationId == const $CopyWithPlaceholder()
          ? _value.conversationId
          // ignore: cast_nullable_to_non_nullable
          : conversationId as String?,
      comments: comments == const $CopyWithPlaceholder() || comments == null
          ? _value.comments
          // ignore: cast_nullable_to_non_nullable
          : comments as int,
      updatedAt: updatedAt == const $CopyWithPlaceholder() || updatedAt == null
          ? _value.updatedAt
          // ignore: cast_nullable_to_non_nullable
          : updatedAt as DateTime,
      createdAt: createdAt == const $CopyWithPlaceholder() || createdAt == null
          ? _value.createdAt
          // ignore: cast_nullable_to_non_nullable
          : createdAt as DateTime,
    );
  }
}

extension $TaskCopyWith on Task {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfTask.copyWith(...)` or `instanceOfTask.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$TaskCWProxy get copyWith => _$TaskCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Task _$TaskFromJson(Map<String, dynamic> json) => $checkedCreate(
  'Task',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'id',
        'title',
        'details_md',
        'status',
        'priority',
        'assignee_bot_id',
        'assignee_user_id',
        'created_by_bot_id',
        'created_by_user_id',
        'result_md',
        'due_at',
        'labels',
        'position',
        'review_required',
        'conversation_id',
        'comments',
        'updated_at',
        'created_at',
      ],
    );
    final val = Task(
      id: $checkedConvert('id', (v) => v as String),
      title: $checkedConvert('title', (v) => v as String),
      detailsMd: $checkedConvert('details_md', (v) => v as String),
      status: $checkedConvert(
        'status',
        (v) => $enumDecode(_$TaskStatusEnumMap, v),
      ),
      priority: $checkedConvert(
        'priority',
        (v) => $enumDecode(_$TaskPriorityEnumMap, v),
      ),
      assigneeBotId: $checkedConvert('assignee_bot_id', (v) => v as String?),
      assigneeUserId: $checkedConvert('assignee_user_id', (v) => v as String?),
      createdByBotId: $checkedConvert('created_by_bot_id', (v) => v as String?),
      createdByUserId: $checkedConvert(
        'created_by_user_id',
        (v) => v as String?,
      ),
      resultMd: $checkedConvert('result_md', (v) => v as String?),
      dueAt: $checkedConvert(
        'due_at',
        (v) => v == null ? null : DateTime.parse(v as String),
      ),
      labels: $checkedConvert(
        'labels',
        (v) => (v as List<dynamic>).map((e) => e as String).toList(),
      ),
      position: $checkedConvert('position', (v) => v as num),
      reviewRequired: $checkedConvert('review_required', (v) => v as bool),
      conversationId: $checkedConvert('conversation_id', (v) => v as String?),
      comments: $checkedConvert('comments', (v) => (v as num).toInt()),
      updatedAt: $checkedConvert(
        'updated_at',
        (v) => DateTime.parse(v as String),
      ),
      createdAt: $checkedConvert(
        'created_at',
        (v) => DateTime.parse(v as String),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'detailsMd': 'details_md',
    'assigneeBotId': 'assignee_bot_id',
    'assigneeUserId': 'assignee_user_id',
    'createdByBotId': 'created_by_bot_id',
    'createdByUserId': 'created_by_user_id',
    'resultMd': 'result_md',
    'dueAt': 'due_at',
    'reviewRequired': 'review_required',
    'conversationId': 'conversation_id',
    'updatedAt': 'updated_at',
    'createdAt': 'created_at',
  },
);

Map<String, dynamic> _$TaskToJson(Task instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'details_md': instance.detailsMd,
  'status': _$TaskStatusEnumMap[instance.status]!,
  'priority': _$TaskPriorityEnumMap[instance.priority]!,
  'assignee_bot_id': instance.assigneeBotId,
  'assignee_user_id': instance.assigneeUserId,
  'created_by_bot_id': instance.createdByBotId,
  'created_by_user_id': instance.createdByUserId,
  'result_md': instance.resultMd,
  'due_at': instance.dueAt?.toIso8601String(),
  'labels': instance.labels,
  'position': instance.position,
  'review_required': instance.reviewRequired,
  'conversation_id': instance.conversationId,
  'comments': instance.comments,
  'updated_at': instance.updatedAt.toIso8601String(),
  'created_at': instance.createdAt.toIso8601String(),
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
