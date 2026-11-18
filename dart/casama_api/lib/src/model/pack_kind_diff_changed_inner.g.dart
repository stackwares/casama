// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pack_kind_diff_changed_inner.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PackKindDiffChangedInnerCWProxy {
  PackKindDiffChangedInner id(String id);

  PackKindDiffChangedInner diff(List<String> diff);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PackKindDiffChangedInner(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PackKindDiffChangedInner(...).copyWith(id: 12, name: "My name")
  /// ```
  PackKindDiffChangedInner call({String id, List<String> diff});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfPackKindDiffChangedInner.copyWith(...)` or call `instanceOfPackKindDiffChangedInner.copyWith.fieldName(value)` for a single field.
class _$PackKindDiffChangedInnerCWProxyImpl
    implements _$PackKindDiffChangedInnerCWProxy {
  const _$PackKindDiffChangedInnerCWProxyImpl(this._value);

  final PackKindDiffChangedInner _value;

  @override
  PackKindDiffChangedInner id(String id) => call(id: id);

  @override
  PackKindDiffChangedInner diff(List<String> diff) => call(diff: diff);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PackKindDiffChangedInner(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PackKindDiffChangedInner(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  PackKindDiffChangedInner call({
    Object? id = const $CopyWithPlaceholder(),
    Object? diff = const $CopyWithPlaceholder(),
  }) {
    return PackKindDiffChangedInner(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      diff: diff == const $CopyWithPlaceholder() || diff == null
          ? _value.diff
          // ignore: cast_nullable_to_non_nullable
          : diff as List<String>,
    );
  }
}

extension $PackKindDiffChangedInnerCopyWith on PackKindDiffChangedInner {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfPackKindDiffChangedInner.copyWith(...)` or `instanceOfPackKindDiffChangedInner.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PackKindDiffChangedInnerCWProxy get copyWith =>
      _$PackKindDiffChangedInnerCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PackKindDiffChangedInner _$PackKindDiffChangedInnerFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('PackKindDiffChangedInner', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['id', 'diff']);
  final val = PackKindDiffChangedInner(
    id: $checkedConvert('id', (v) => v as String),
    diff: $checkedConvert(
      'diff',
      (v) => (v as List<dynamic>).map((e) => e as String).toList(),
    ),
  );
  return val;
});

Map<String, dynamic> _$PackKindDiffChangedInnerToJson(
  PackKindDiffChangedInner instance,
) => <String, dynamic>{'id': instance.id, 'diff': instance.diff};
