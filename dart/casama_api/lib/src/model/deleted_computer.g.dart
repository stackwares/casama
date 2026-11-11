// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'deleted_computer.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$DeletedComputerCWProxy {
  DeletedComputer deleted(String deleted);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DeletedComputer(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DeletedComputer(...).copyWith(id: 12, name: "My name")
  /// ```
  DeletedComputer call({String deleted});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfDeletedComputer.copyWith(...)` or call `instanceOfDeletedComputer.copyWith.fieldName(value)` for a single field.
class _$DeletedComputerCWProxyImpl implements _$DeletedComputerCWProxy {
  const _$DeletedComputerCWProxyImpl(this._value);

  final DeletedComputer _value;

  @override
  DeletedComputer deleted(String deleted) => call(deleted: deleted);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DeletedComputer(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DeletedComputer(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  DeletedComputer call({Object? deleted = const $CopyWithPlaceholder()}) {
    return DeletedComputer(
      deleted: deleted == const $CopyWithPlaceholder() || deleted == null
          ? _value.deleted
          // ignore: cast_nullable_to_non_nullable
          : deleted as String,
    );
  }
}

extension $DeletedComputerCopyWith on DeletedComputer {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfDeletedComputer.copyWith(...)` or `instanceOfDeletedComputer.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$DeletedComputerCWProxy get copyWith => _$DeletedComputerCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeletedComputer _$DeletedComputerFromJson(Map<String, dynamic> json) =>
    $checkedCreate('DeletedComputer', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['deleted']);
      final val = DeletedComputer(
        deleted: $checkedConvert('deleted', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$DeletedComputerToJson(DeletedComputer instance) =>
    <String, dynamic>{'deleted': instance.deleted};
