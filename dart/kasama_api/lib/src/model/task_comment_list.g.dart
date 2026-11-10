// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_comment_list.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$TaskCommentListCWProxy {
  TaskCommentList items(List<TaskComment> items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `TaskCommentList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// TaskCommentList(...).copyWith(id: 12, name: "My name")
  /// ```
  TaskCommentList call({List<TaskComment> items});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfTaskCommentList.copyWith(...)` or call `instanceOfTaskCommentList.copyWith.fieldName(value)` for a single field.
class _$TaskCommentListCWProxyImpl implements _$TaskCommentListCWProxy {
  const _$TaskCommentListCWProxyImpl(this._value);

  final TaskCommentList _value;

  @override
  TaskCommentList items(List<TaskComment> items) => call(items: items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `TaskCommentList(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// TaskCommentList(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  TaskCommentList call({Object? items = const $CopyWithPlaceholder()}) {
    return TaskCommentList(
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<TaskComment>,
    );
  }
}

extension $TaskCommentListCopyWith on TaskCommentList {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfTaskCommentList.copyWith(...)` or `instanceOfTaskCommentList.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$TaskCommentListCWProxy get copyWith => _$TaskCommentListCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TaskCommentList _$TaskCommentListFromJson(Map<String, dynamic> json) =>
    $checkedCreate('TaskCommentList', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['items']);
      final val = TaskCommentList(
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => TaskComment.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$TaskCommentListToJson(TaskCommentList instance) =>
    <String, dynamic>{'items': instance.items.map((e) => e.toJson()).toList()};
