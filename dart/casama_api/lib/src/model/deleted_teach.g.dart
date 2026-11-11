// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'deleted_teach.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$DeletedTeachCWProxy {
  DeletedTeach deleted(String deleted);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DeletedTeach(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DeletedTeach(...).copyWith(id: 12, name: "My name")
  /// ```
  DeletedTeach call({String deleted});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfDeletedTeach.copyWith(...)` or call `instanceOfDeletedTeach.copyWith.fieldName(value)` for a single field.
class _$DeletedTeachCWProxyImpl implements _$DeletedTeachCWProxy {
  const _$DeletedTeachCWProxyImpl(this._value);

  final DeletedTeach _value;

  @override
  DeletedTeach deleted(String deleted) => call(deleted: deleted);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DeletedTeach(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DeletedTeach(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  DeletedTeach call({Object? deleted = const $CopyWithPlaceholder()}) {
    return DeletedTeach(
      deleted: deleted == const $CopyWithPlaceholder() || deleted == null
          ? _value.deleted
          // ignore: cast_nullable_to_non_nullable
          : deleted as String,
    );
  }
}

extension $DeletedTeachCopyWith on DeletedTeach {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfDeletedTeach.copyWith(...)` or `instanceOfDeletedTeach.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$DeletedTeachCWProxy get copyWith => _$DeletedTeachCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeletedTeach _$DeletedTeachFromJson(Map<String, dynamic> json) =>
    $checkedCreate('DeletedTeach', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['deleted']);
      final val = DeletedTeach(
        deleted: $checkedConvert('deleted', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$DeletedTeachToJson(DeletedTeach instance) =>
    <String, dynamic>{'deleted': instance.deleted};
