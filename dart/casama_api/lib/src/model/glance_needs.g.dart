// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'glance_needs.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$GlanceNeedsCWProxy {
  GlanceNeeds count(int count);

  GlanceNeeds items(List<GlanceNeed> items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `GlanceNeeds(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// GlanceNeeds(...).copyWith(id: 12, name: "My name")
  /// ```
  GlanceNeeds call({int count, List<GlanceNeed> items});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfGlanceNeeds.copyWith(...)` or call `instanceOfGlanceNeeds.copyWith.fieldName(value)` for a single field.
class _$GlanceNeedsCWProxyImpl implements _$GlanceNeedsCWProxy {
  const _$GlanceNeedsCWProxyImpl(this._value);

  final GlanceNeeds _value;

  @override
  GlanceNeeds count(int count) => call(count: count);

  @override
  GlanceNeeds items(List<GlanceNeed> items) => call(items: items);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `GlanceNeeds(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// GlanceNeeds(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  GlanceNeeds call({
    Object? count = const $CopyWithPlaceholder(),
    Object? items = const $CopyWithPlaceholder(),
  }) {
    return GlanceNeeds(
      count: count == const $CopyWithPlaceholder() || count == null
          ? _value.count
          // ignore: cast_nullable_to_non_nullable
          : count as int,
      items: items == const $CopyWithPlaceholder() || items == null
          ? _value.items
          // ignore: cast_nullable_to_non_nullable
          : items as List<GlanceNeed>,
    );
  }
}

extension $GlanceNeedsCopyWith on GlanceNeeds {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfGlanceNeeds.copyWith(...)` or `instanceOfGlanceNeeds.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$GlanceNeedsCWProxy get copyWith => _$GlanceNeedsCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GlanceNeeds _$GlanceNeedsFromJson(Map<String, dynamic> json) =>
    $checkedCreate('GlanceNeeds', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['count', 'items']);
      final val = GlanceNeeds(
        count: $checkedConvert('count', (v) => (v as num).toInt()),
        items: $checkedConvert(
          'items',
          (v) => (v as List<dynamic>)
              .map((e) => GlanceNeed.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$GlanceNeedsToJson(GlanceNeeds instance) =>
    <String, dynamic>{
      'count': instance.count,
      'items': instance.items.map((e) => e.toJson()).toList(),
    };
