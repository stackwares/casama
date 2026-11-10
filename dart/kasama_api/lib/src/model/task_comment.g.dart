// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_comment.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$TaskCommentCWProxy {
  TaskComment id(String id);

  TaskComment taskId(String taskId);

  TaskComment authorType(TaskCommentAuthorTypeEnum authorType);

  TaskComment authorUserId(String? authorUserId);

  TaskComment authorBotId(String? authorBotId);

  TaskComment bodyMd(String bodyMd);

  TaskComment createdAt(DateTime createdAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `TaskComment(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// TaskComment(...).copyWith(id: 12, name: "My name")
  /// ```
  TaskComment call({
    String id,
    String taskId,
    TaskCommentAuthorTypeEnum authorType,
    String? authorUserId,
    String? authorBotId,
    String bodyMd,
    DateTime createdAt,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfTaskComment.copyWith(...)` or call `instanceOfTaskComment.copyWith.fieldName(value)` for a single field.
class _$TaskCommentCWProxyImpl implements _$TaskCommentCWProxy {
  const _$TaskCommentCWProxyImpl(this._value);

  final TaskComment _value;

  @override
  TaskComment id(String id) => call(id: id);

  @override
  TaskComment taskId(String taskId) => call(taskId: taskId);

  @override
  TaskComment authorType(TaskCommentAuthorTypeEnum authorType) =>
      call(authorType: authorType);

  @override
  TaskComment authorUserId(String? authorUserId) =>
      call(authorUserId: authorUserId);

  @override
  TaskComment authorBotId(String? authorBotId) =>
      call(authorBotId: authorBotId);

  @override
  TaskComment bodyMd(String bodyMd) => call(bodyMd: bodyMd);

  @override
  TaskComment createdAt(DateTime createdAt) => call(createdAt: createdAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `TaskComment(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// TaskComment(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  TaskComment call({
    Object? id = const $CopyWithPlaceholder(),
    Object? taskId = const $CopyWithPlaceholder(),
    Object? authorType = const $CopyWithPlaceholder(),
    Object? authorUserId = const $CopyWithPlaceholder(),
    Object? authorBotId = const $CopyWithPlaceholder(),
    Object? bodyMd = const $CopyWithPlaceholder(),
    Object? createdAt = const $CopyWithPlaceholder(),
  }) {
    return TaskComment(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      taskId: taskId == const $CopyWithPlaceholder() || taskId == null
          ? _value.taskId
          // ignore: cast_nullable_to_non_nullable
          : taskId as String,
      authorType:
          authorType == const $CopyWithPlaceholder() || authorType == null
          ? _value.authorType
          // ignore: cast_nullable_to_non_nullable
          : authorType as TaskCommentAuthorTypeEnum,
      authorUserId: authorUserId == const $CopyWithPlaceholder()
          ? _value.authorUserId
          // ignore: cast_nullable_to_non_nullable
          : authorUserId as String?,
      authorBotId: authorBotId == const $CopyWithPlaceholder()
          ? _value.authorBotId
          // ignore: cast_nullable_to_non_nullable
          : authorBotId as String?,
      bodyMd: bodyMd == const $CopyWithPlaceholder() || bodyMd == null
          ? _value.bodyMd
          // ignore: cast_nullable_to_non_nullable
          : bodyMd as String,
      createdAt: createdAt == const $CopyWithPlaceholder() || createdAt == null
          ? _value.createdAt
          // ignore: cast_nullable_to_non_nullable
          : createdAt as DateTime,
    );
  }
}

extension $TaskCommentCopyWith on TaskComment {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfTaskComment.copyWith(...)` or `instanceOfTaskComment.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$TaskCommentCWProxy get copyWith => _$TaskCommentCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TaskComment _$TaskCommentFromJson(Map<String, dynamic> json) => $checkedCreate(
  'TaskComment',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'id',
        'task_id',
        'author_type',
        'author_user_id',
        'author_bot_id',
        'body_md',
        'created_at',
      ],
    );
    final val = TaskComment(
      id: $checkedConvert('id', (v) => v as String),
      taskId: $checkedConvert('task_id', (v) => v as String),
      authorType: $checkedConvert(
        'author_type',
        (v) => $enumDecode(_$TaskCommentAuthorTypeEnumEnumMap, v),
      ),
      authorUserId: $checkedConvert('author_user_id', (v) => v as String?),
      authorBotId: $checkedConvert('author_bot_id', (v) => v as String?),
      bodyMd: $checkedConvert('body_md', (v) => v as String),
      createdAt: $checkedConvert(
        'created_at',
        (v) => DateTime.parse(v as String),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'taskId': 'task_id',
    'authorType': 'author_type',
    'authorUserId': 'author_user_id',
    'authorBotId': 'author_bot_id',
    'bodyMd': 'body_md',
    'createdAt': 'created_at',
  },
);

Map<String, dynamic> _$TaskCommentToJson(TaskComment instance) =>
    <String, dynamic>{
      'id': instance.id,
      'task_id': instance.taskId,
      'author_type': _$TaskCommentAuthorTypeEnumEnumMap[instance.authorType]!,
      'author_user_id': instance.authorUserId,
      'author_bot_id': instance.authorBotId,
      'body_md': instance.bodyMd,
      'created_at': instance.createdAt.toIso8601String(),
    };

const _$TaskCommentAuthorTypeEnumEnumMap = {
  TaskCommentAuthorTypeEnum.user: 'user',
  TaskCommentAuthorTypeEnum.bot: 'bot',
};
