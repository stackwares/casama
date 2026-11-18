// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'glance_tasks.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$GlanceTasksCWProxy {
  GlanceTasks counts(GlanceTasksCounts counts);

  GlanceTasks items(List<GlanceTask> items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `GlanceTasks(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// GlanceTasks(...).copyWith(id: 12, name: "My name")
  /// ```
  GlanceTasks call({GlanceTasksCounts counts, List<GlanceTask> items});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfGlanceTasks.copyWith(...)` or call `instanceOfGlanceTasks.copyWith.fieldName(value)` for a single field.
class _$GlanceTasksCWProxyImpl implements _$GlanceTasksCWProxy {
  const _$GlanceTasksCWProxyImpl(this._value);

  final GlanceTasks _value;

  @override
  GlanceTasks counts(GlanceTasksCounts counts) => call(counts: counts);

  @override
  GlanceTasks items(List<GlanceTask> items) => call(items: items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `GlanceTasks(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// GlanceTasks(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  GlanceTasks call({
    Object? counts = const $CopyWithPlaceholder(),
    Object? items = const $CopyWithPlaceholder(),
  }) {
    return GlanceTasks(
      counts: counts == const $CopyWithPlaceholder() || counts == null
          ? _value.counts
          // ignore: cast_nullable_to_non_nullable
          : counts as GlanceTasksCounts,
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<GlanceTask>,
    );
  }
}

extension $GlanceTasksCopyWith on GlanceTasks {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfGlanceTasks.copyWith(...)` or `instanceOfGlanceTasks.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$GlanceTasksCWProxy get copyWith => _$GlanceTasksCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GlanceTasks _$GlanceTasksFromJson(Map<String, dynamic> json) =>
    $checkedCreate('GlanceTasks', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['counts', 'items']);
      final val = GlanceTasks(
        counts: $checkedConvert(
          'counts',
          (v) => GlanceTasksCounts.fromJson(v as Map<String, dynamic>),
        ),
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => GlanceTask.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$GlanceTasksToJson(GlanceTasks instance) =>
    <String, dynamic>{
      'counts': instance.counts.toJson(),
      'items': instance.items.map((e) => e.toJson()).toList(),
    };
