// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$TaskCWProxy {
  Task id(String id);

  Task title(String title);

  Task detailsMd(String detailsMd);

  Task status(TaskStatusEnum status);

  Task assigneeBotId(String? assigneeBotId);

  Task createdByBotId(String? createdByBotId);

  Task resultMd(String? resultMd);

  Task updatedAt(DateTime updatedAt);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Task(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Task(...).copyWith(id: 12, name: "My name")
  /// ````
  Task call({
    String id,
    String title,
    String detailsMd,
    TaskStatusEnum status,
    String? assigneeBotId,
    String? createdByBotId,
    String? resultMd,
    DateTime updatedAt,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfTask.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfTask.copyWith.fieldName(...)`
class _$TaskCWProxyImpl implements _$TaskCWProxy {
  const _$TaskCWProxyImpl(this._value);

  final Task _value;

  @override
  Task id(String id) => this(id: id);

  @override
  Task title(String title) => this(title: title);

  @override
  Task detailsMd(String detailsMd) => this(detailsMd: detailsMd);

  @override
  Task status(TaskStatusEnum status) => this(status: status);

  @override
  Task assigneeBotId(String? assigneeBotId) =>
      this(assigneeBotId: assigneeBotId);

  @override
  Task createdByBotId(String? createdByBotId) =>
      this(createdByBotId: createdByBotId);

  @override
  Task resultMd(String? resultMd) => this(resultMd: resultMd);

  @override
  Task updatedAt(DateTime updatedAt) => this(updatedAt: updatedAt);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `Task(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// Task(...).copyWith(id: 12, name: "My name")
  /// ````
  Task call({
    Object? id = const $CopyWithPlaceholder(),
    Object? title = const $CopyWithPlaceholder(),
    Object? detailsMd = const $CopyWithPlaceholder(),
    Object? status = const $CopyWithPlaceholder(),
    Object? assigneeBotId = const $CopyWithPlaceholder(),
    Object? createdByBotId = const $CopyWithPlaceholder(),
    Object? resultMd = const $CopyWithPlaceholder(),
    Object? updatedAt = const $CopyWithPlaceholder(),
  }) {
    return Task(
      id: id == const $CopyWithPlaceholder()
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      title: title == const $CopyWithPlaceholder()
          ? _value.title
          // ignore: cast_nullable_to_non_nullable
          : title as String,
      detailsMd: detailsMd == const $CopyWithPlaceholder()
          ? _value.detailsMd
          // ignore: cast_nullable_to_non_nullable
          : detailsMd as String,
      status: status == const $CopyWithPlaceholder()
          ? _value.status
          // ignore: cast_nullable_to_non_nullable
          : status as TaskStatusEnum,
      assigneeBotId: assigneeBotId == const $CopyWithPlaceholder()
          ? _value.assigneeBotId
          // ignore: cast_nullable_to_non_nullable
          : assigneeBotId as String?,
      createdByBotId: createdByBotId == const $CopyWithPlaceholder()
          ? _value.createdByBotId
          // ignore: cast_nullable_to_non_nullable
          : createdByBotId as String?,
      resultMd: resultMd == const $CopyWithPlaceholder()
          ? _value.resultMd
          // ignore: cast_nullable_to_non_nullable
          : resultMd as String?,
      updatedAt: updatedAt == const $CopyWithPlaceholder()
          ? _value.updatedAt
          // ignore: cast_nullable_to_non_nullable
          : updatedAt as DateTime,
    );
  }
}

extension $TaskCopyWith on Task {
  /// Returns a callable class that can be used as follows: `instanceOfTask.copyWith(...)` or like so:`instanceOfTask.copyWith.fieldName(...)`.
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
        'assignee_bot_id',
        'created_by_bot_id',
        'result_md',
        'updated_at',
      ],
    );
    final val = Task(
      id: $checkedConvert('id', (v) => v as String),
      title: $checkedConvert('title', (v) => v as String),
      detailsMd: $checkedConvert('details_md', (v) => v as String),
      status: $checkedConvert(
        'status',
        (v) => $enumDecode(_$TaskStatusEnumEnumMap, v),
      ),
      assigneeBotId: $checkedConvert('assignee_bot_id', (v) => v as String?),
      createdByBotId: $checkedConvert('created_by_bot_id', (v) => v as String?),
      resultMd: $checkedConvert('result_md', (v) => v as String?),
      updatedAt: $checkedConvert(
        'updated_at',
        (v) => DateTime.parse(v as String),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'detailsMd': 'details_md',
    'assigneeBotId': 'assignee_bot_id',
    'createdByBotId': 'created_by_bot_id',
    'resultMd': 'result_md',
    'updatedAt': 'updated_at',
  },
);

Map<String, dynamic> _$TaskToJson(Task instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'details_md': instance.detailsMd,
  'status': _$TaskStatusEnumEnumMap[instance.status]!,
  'assignee_bot_id': instance.assigneeBotId,
  'created_by_bot_id': instance.createdByBotId,
  'result_md': instance.resultMd,
  'updated_at': instance.updatedAt.toIso8601String(),
};

const _$TaskStatusEnumEnumMap = {
  TaskStatusEnum.todo: 'todo',
  TaskStatusEnum.doing: 'doing',
  TaskStatusEnum.done: 'done',
  TaskStatusEnum.blocked: 'blocked',
};
