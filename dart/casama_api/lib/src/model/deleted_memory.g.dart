// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'deleted_memory.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$DeletedMemoryCWProxy {
  DeletedMemory deleted(String deleted);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DeletedMemory(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DeletedMemory(...).copyWith(id: 12, name: "My name")
  /// ```
  DeletedMemory call({String deleted});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfDeletedMemory.copyWith(...)` or call `instanceOfDeletedMemory.copyWith.fieldName(value)` for a single field.
class _$DeletedMemoryCWProxyImpl implements _$DeletedMemoryCWProxy {
  const _$DeletedMemoryCWProxyImpl(this._value);

  final DeletedMemory _value;

  @override
  DeletedMemory deleted(String deleted) => call(deleted: deleted);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DeletedMemory(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DeletedMemory(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  DeletedMemory call({Object? deleted = const $CopyWithPlaceholder()}) {
    return DeletedMemory(
      deleted: deleted == const $CopyWithPlaceholder() || deleted == null
          ? _value.deleted
          // ignore: cast_nullable_to_non_nullable
          : deleted as String,
    );
  }
}

extension $DeletedMemoryCopyWith on DeletedMemory {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfDeletedMemory.copyWith(...)` or `instanceOfDeletedMemory.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$DeletedMemoryCWProxy get copyWith => _$DeletedMemoryCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeletedMemory _$DeletedMemoryFromJson(Map<String, dynamic> json) =>
    $checkedCreate('DeletedMemory', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['deleted']);
      final val = DeletedMemory(
        deleted: $checkedConvert('deleted', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$DeletedMemoryToJson(DeletedMemory instance) =>
    <String, dynamic>{'deleted': instance.deleted};
