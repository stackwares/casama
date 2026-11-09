// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_list.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$TaskListCWProxy {
  TaskList items(List<Task> items);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `TaskList(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// TaskList(...).copyWith(id: 12, name: "My name")
  /// ````
  TaskList call({List<Task> items});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfTaskList.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfTaskList.copyWith.fieldName(...)`
class _$TaskListCWProxyImpl implements _$TaskListCWProxy {
  const _$TaskListCWProxyImpl(this._value);

  final TaskList _value;

  @override
  TaskList items(List<Task> items) => this(items: items);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `TaskList(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// TaskList(...).copyWith(id: 12, name: "My name")
  /// ````
  TaskList call({Object? items = const $CopyWithPlaceholder()}) {
    return TaskList(
      items: items == const $CopyWithPlaceholder()
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<Task>,
    );
  }
}

extension $TaskListCopyWith on TaskList {
  /// Returns a callable class that can be used as follows: `instanceOfTaskList.copyWith(...)` or like so:`instanceOfTaskList.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$TaskListCWProxy get copyWith => _$TaskListCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TaskList _$TaskListFromJson(Map<String, dynamic> json) =>
    $checkedCreate('TaskList', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items']);
      final val = TaskList(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => Task.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$TaskListToJson(TaskList instance) => <String, dynamic>{
  'items': instance.items.map((e) => e.toJson()).toList(),
};
