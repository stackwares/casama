// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_task_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$UpdateTaskRequestCWProxy {
  UpdateTaskRequest title(String? title);

  UpdateTaskRequest detailsMd(String? detailsMd);

  UpdateTaskRequest status(TaskStatus? status);

  UpdateTaskRequest priority(TaskPriority? priority);

  UpdateTaskRequest assigneeBotId(String? assigneeBotId);

  UpdateTaskRequest assigneeUserId(String? assigneeUserId);

  UpdateTaskRequest dueAt(DateTime? dueAt);

  UpdateTaskRequest labels(List<String>? labels);

  UpdateTaskRequest reviewRequired(bool? reviewRequired);

  UpdateTaskRequest position(num? position);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `UpdateTaskRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// UpdateTaskRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  UpdateTaskRequest call({
    String? title,
    String? detailsMd,
    TaskStatus? status,
    TaskPriority? priority,
    String? assigneeBotId,
    String? assigneeUserId,
    DateTime? dueAt,
    List<String>? labels,
    bool? reviewRequired,
    num? position,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfUpdateTaskRequest.copyWith(...)` or call `instanceOfUpdateTaskRequest.copyWith.fieldName(value)` for a single field.
class _$UpdateTaskRequestCWProxyImpl implements _$UpdateTaskRequestCWProxy {
  const _$UpdateTaskRequestCWProxyImpl(this._value);

  final UpdateTaskRequest _value;

  @override
  UpdateTaskRequest title(String? title) => call(title: title);

  @override
  UpdateTaskRequest detailsMd(String? detailsMd) => call(detailsMd: detailsMd);

  @override
  UpdateTaskRequest status(TaskStatus? status) => call(status: status);

  @override
  UpdateTaskRequest priority(TaskPriority? priority) =>
      call(priority: priority);

  @override
  UpdateTaskRequest assigneeBotId(String? assigneeBotId) =>
      call(assigneeBotId: assigneeBotId);

  @override
  UpdateTaskRequest assigneeUserId(String? assigneeUserId) =>
      call(assigneeUserId: assigneeUserId);

  @override
  UpdateTaskRequest dueAt(DateTime? dueAt) => call(dueAt: dueAt);

  @override
  UpdateTaskRequest labels(List<String>? labels) => call(labels: labels);

  @override
  UpdateTaskRequest reviewRequired(bool? reviewRequired) =>
      call(reviewRequired: reviewRequired);

  @override
  UpdateTaskRequest position(num? position) => call(position: position);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `UpdateTaskRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// UpdateTaskRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  UpdateTaskRequest call({
    Object? title = const $CopyWithPlaceholder(),
    Object? detailsMd = const $CopyWithPlaceholder(),
    Object? status = const $CopyWithPlaceholder(),
    Object? priority = const $CopyWithPlaceholder(),
    Object? assigneeBotId = const $CopyWithPlaceholder(),
    Object? assigneeUserId = const $CopyWithPlaceholder(),
    Object? dueAt = const $CopyWithPlaceholder(),
    Object? labels = const $CopyWithPlaceholder(),
    Object? reviewRequired = const $CopyWithPlaceholder(),
    Object? position = const $CopyWithPlaceholder(),
  }) {
    return UpdateTaskRequest(
      title: title == const $CopyWithPlaceholder()
          ? _value.title
          // ignore: cast_nullable_to_non_nullable
          : title as String?,
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
      position: position == const $CopyWithPlaceholder()
          ? _value.position
          // ignore: cast_nullable_to_non_nullable
          : position as num?,
    );
  }
}

extension $UpdateTaskRequestCopyWith on UpdateTaskRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfUpdateTaskRequest.copyWith(...)` or `instanceOfUpdateTaskRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$UpdateTaskRequestCWProxy get copyWith =>
      _$UpdateTaskRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UpdateTaskRequest _$UpdateTaskRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'UpdateTaskRequest',
  json,
  ($checkedConvert) {
    final val = UpdateTaskRequest(
      title: $checkedConvert('title', (v) => v as String?),
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
      position: $checkedConvert('position', (v) => v as num?),
    );
    return val;
  },
  fieldKeyMap: const {
    'detailsMd': 'details_md',
    'assigneeBotId': 'assignee_bot_id',
    'assigneeUserId': 'assignee_user_id',
    'dueAt': 'due_at',
    'reviewRequired': 'review_required',
  },
);

Map<String, dynamic> _$UpdateTaskRequestToJson(UpdateTaskRequest instance) =>
    <String, dynamic>{
      'title': ?instance.title,
      'details_md': ?instance.detailsMd,
      'status': ?_$TaskStatusEnumMap[instance.status],
      'priority': ?_$TaskPriorityEnumMap[instance.priority],
      'assignee_bot_id': ?instance.assigneeBotId,
      'assignee_user_id': ?instance.assigneeUserId,
      'due_at': ?instance.dueAt?.toIso8601String(),
      'labels': ?instance.labels,
      'review_required': ?instance.reviewRequired,
      'position': ?instance.position,
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
