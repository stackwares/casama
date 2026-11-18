// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'glance_tasks_counts.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$GlanceTasksCountsCWProxy {
  GlanceTasksCounts todo(int todo);

  GlanceTasksCounts inProgress(int inProgress);

  GlanceTasksCounts inReview(int inReview);

  GlanceTasksCounts blocked(int blocked);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `GlanceTasksCounts(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// GlanceTasksCounts(...).copyWith(id: 12, name: "My name")
  /// ```
  GlanceTasksCounts call({int todo, int inProgress, int inReview, int blocked});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfGlanceTasksCounts.copyWith(...)` or call `instanceOfGlanceTasksCounts.copyWith.fieldName(value)` for a single field.
class _$GlanceTasksCountsCWProxyImpl implements _$GlanceTasksCountsCWProxy {
  const _$GlanceTasksCountsCWProxyImpl(this._value);

  final GlanceTasksCounts _value;

  @override
  GlanceTasksCounts todo(int todo) => call(todo: todo);

  @override
  GlanceTasksCounts inProgress(int inProgress) => call(inProgress: inProgress);

  @override
  GlanceTasksCounts inReview(int inReview) => call(inReview: inReview);

  @override
  GlanceTasksCounts blocked(int blocked) => call(blocked: blocked);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `GlanceTasksCounts(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// GlanceTasksCounts(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  GlanceTasksCounts call({
    Object? todo = const $CopyWithPlaceholder(),
    Object? inProgress = const $CopyWithPlaceholder(),
    Object? inReview = const $CopyWithPlaceholder(),
    Object? blocked = const $CopyWithPlaceholder(),
  }) {
    return GlanceTasksCounts(
      todo: todo == const $CopyWithPlaceholder() || todo == null
          ? _value.todo
          // ignore: cast_nullable_to_non_nullable
          : todo as int,
      inProgress:
          inProgress == const $CopyWithPlaceholder() || inProgress == null
          ? _value.inProgress
          // ignore: cast_nullable_to_non_nullable
          : inProgress as int,
      inReview: inReview == const $CopyWithPlaceholder() || inReview == null
          ? _value.inReview
          // ignore: cast_nullable_to_non_nullable
          : inReview as int,
      blocked: blocked == const $CopyWithPlaceholder() || blocked == null
          ? _value.blocked
          // ignore: cast_nullable_to_non_nullable
          : blocked as int,
    );
  }
}

extension $GlanceTasksCountsCopyWith on GlanceTasksCounts {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfGlanceTasksCounts.copyWith(...)` or `instanceOfGlanceTasksCounts.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$GlanceTasksCountsCWProxy get copyWith =>
      _$GlanceTasksCountsCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GlanceTasksCounts _$GlanceTasksCountsFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'GlanceTasksCounts',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const ['todo', 'in_progress', 'in_review', 'blocked'],
        );
        final val = GlanceTasksCounts(
          todo: $checkedConvert('todo', (v) => (v as num).toInt()),
          inProgress: $checkedConvert('in_progress', (v) => (v as num).toInt()),
          inReview: $checkedConvert('in_review', (v) => (v as num).toInt()),
          blocked: $checkedConvert('blocked', (v) => (v as num).toInt()),
        );
        return val;
      },
      fieldKeyMap: const {'inProgress': 'in_progress', 'inReview': 'in_review'},
    );

Map<String, dynamic> _$GlanceTasksCountsToJson(GlanceTasksCounts instance) =>
    <String, dynamic>{
      'todo': instance.todo,
      'in_progress': instance.inProgress,
      'in_review': instance.inReview,
      'blocked': instance.blocked,
    };
