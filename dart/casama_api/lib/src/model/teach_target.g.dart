// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'teach_target.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$TeachTargetCWProxy {
  TeachTarget role(String? role);

  TeachTarget name(String name);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `TeachTarget(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// TeachTarget(...).copyWith(id: 12, name: "My name")
  /// ```
  TeachTarget call({String? role, String name});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfTeachTarget.copyWith(...)` or call `instanceOfTeachTarget.copyWith.fieldName(value)` for a single field.
class _$TeachTargetCWProxyImpl implements _$TeachTargetCWProxy {
  const _$TeachTargetCWProxyImpl(this._value);

  final TeachTarget _value;

  @override
  TeachTarget role(String? role) => call(role: role);

  @override
  TeachTarget name(String name) => call(name: name);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `TeachTarget(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// TeachTarget(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  TeachTarget call({
    Object? role = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
  }) {
    return TeachTarget(
      role: role == const $CopyWithPlaceholder()
          ? _value.role
          // ignore: cast_nullable_to_non_nullable
          : role as String?,
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
    );
  }
}

extension $TeachTargetCopyWith on TeachTarget {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfTeachTarget.copyWith(...)` or `instanceOfTeachTarget.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$TeachTargetCWProxy get copyWith => _$TeachTargetCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TeachTarget _$TeachTargetFromJson(Map<String, dynamic> json) =>
    $checkedCreate('TeachTarget', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['name']);
      final val = TeachTarget(
        role: $checkedConvert('role', (v) => v as String?),
        name: $checkedConvert('name', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$TeachTargetToJson(TeachTarget instance) =>
    <String, dynamic>{'role': ?instance.role, 'name': instance.name};
