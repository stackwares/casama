// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_list.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$TaskListCWProxy {
  TaskList items(List<Task> items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `TaskList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// TaskList(...).copyWith(id: 12, name: "My name")
  /// ```
  TaskList call({List<Task> items});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfTaskList.copyWith(...)` or call `instanceOfTaskList.copyWith.fieldName(value)` for a single field.
class _$TaskListCWProxyImpl implements _$TaskListCWProxy {
  const _$TaskListCWProxyImpl(this._value);

  final TaskList _value;

  @override
  TaskList items(List<Task> items) => call(items: items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `TaskList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// TaskList(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  TaskList call({Object? items = const $CopyWithPlaceholder()}) {
    return TaskList(
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<Task>,
    );
  }
}

extension $TaskListCopyWith on TaskList {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfTaskList.copyWith(...)` or `instanceOfTaskList.copyWith.fieldName(...)`.
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
