// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pack_kind_diff.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PackKindDiffCWProxy {
  PackKindDiff added(List<String> added);

  PackKindDiff removed(List<String> removed);

  PackKindDiff changed(List<PackKindDiffChangedInner> changed);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PackKindDiff(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PackKindDiff(...).copyWith(id: 12, name: "My name")
  /// ```
  PackKindDiff call({
    List<String> added,
    List<String> removed,
    List<PackKindDiffChangedInner> changed,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfPackKindDiff.copyWith(...)` or call `instanceOfPackKindDiff.copyWith.fieldName(value)` for a single field.
class _$PackKindDiffCWProxyImpl implements _$PackKindDiffCWProxy {
  const _$PackKindDiffCWProxyImpl(this._value);

  final PackKindDiff _value;

  @override
  PackKindDiff added(List<String> added) => call(added: added);

  @override
  PackKindDiff removed(List<String> removed) => call(removed: removed);

  @override
  PackKindDiff changed(List<PackKindDiffChangedInner> changed) =>
      call(changed: changed);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PackKindDiff(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PackKindDiff(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  PackKindDiff call({
    Object? added = const $CopyWithPlaceholder(),
    Object? removed = const $CopyWithPlaceholder(),
    Object? changed = const $CopyWithPlaceholder(),
  }) {
    return PackKindDiff(
      added: added == const $CopyWithPlaceholder() || added == null
          ? _value.added
          // ignore: cast_nullable_to_non_nullable
          : added as List<String>,
      removed: removed == const $CopyWithPlaceholder() || removed == null
          ? _value.removed
          // ignore: cast_nullable_to_non_nullable
          : removed as List<String>,
      changed: changed == const $CopyWithPlaceholder() || changed == null
          ? _value.changed
          // ignore: cast_nullable_to_non_nullable
          : changed as List<PackKindDiffChangedInner>,
    );
  }
}

extension $PackKindDiffCopyWith on PackKindDiff {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfPackKindDiff.copyWith(...)` or `instanceOfPackKindDiff.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PackKindDiffCWProxy get copyWith => _$PackKindDiffCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PackKindDiff _$PackKindDiffFromJson(Map<String, dynamic> json) =>
    $checkedCreate('PackKindDiff', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['added', 'removed', 'changed']);
      final val = PackKindDiff(
        added: $checkedConvert(
          'added',
          (v) => (v as List<dynamic>).map((e) => e as String).toList(),
        ),
        removed: $checkedConvert(
          'removed',
          (v) => (v as List<dynamic>).map((e) => e as String).toList(),
        ),
        changed: $checkedConvert(
          'changed',
          (v) => (v as List<dynamic>)
              .map(
                (e) => PackKindDiffChangedInner.fromJson(
                  e as Map<String, dynamic>,
                ),
              )
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$PackKindDiffToJson(PackKindDiff instance) =>
    <String, dynamic>{
      'added': instance.added,
      'removed': instance.removed,
      'changed': instance.changed.map((e) => e.toJson()).toList(),
    };
