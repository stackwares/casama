// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'deleted_id.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$DeletedIdCWProxy {
  DeletedId deleted(String deleted);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DeletedId(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DeletedId(...).copyWith(id: 12, name: "My name")
  /// ```
  DeletedId call({String deleted});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfDeletedId.copyWith(...)` or call `instanceOfDeletedId.copyWith.fieldName(value)` for a single field.
class _$DeletedIdCWProxyImpl implements _$DeletedIdCWProxy {
  const _$DeletedIdCWProxyImpl(this._value);

  final DeletedId _value;

  @override
  DeletedId deleted(String deleted) => call(deleted: deleted);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DeletedId(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DeletedId(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  DeletedId call({Object? deleted = const $CopyWithPlaceholder()}) {
    return DeletedId(
      deleted: deleted == const $CopyWithPlaceholder() || deleted == null
          ? _value.deleted
          // ignore: cast_nullable_to_non_nullable
          : deleted as String,
    );
  }
}

extension $DeletedIdCopyWith on DeletedId {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfDeletedId.copyWith(...)` or `instanceOfDeletedId.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$DeletedIdCWProxy get copyWith => _$DeletedIdCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeletedId _$DeletedIdFromJson(Map<String, dynamic> json) =>
    $checkedCreate('DeletedId', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['deleted']);
      final val = DeletedId(
        deleted: $checkedConvert('deleted', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$DeletedIdToJson(DeletedId instance) => <String, dynamic>{
  'deleted': instance.deleted,
};
