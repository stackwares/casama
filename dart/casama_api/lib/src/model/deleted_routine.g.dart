// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'deleted_routine.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$DeletedRoutineCWProxy {
  DeletedRoutine deleted(String deleted);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DeletedRoutine(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DeletedRoutine(...).copyWith(id: 12, name: "My name")
  /// ```
  DeletedRoutine call({String deleted});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfDeletedRoutine.copyWith(...)` or call `instanceOfDeletedRoutine.copyWith.fieldName(value)` for a single field.
class _$DeletedRoutineCWProxyImpl implements _$DeletedRoutineCWProxy {
  const _$DeletedRoutineCWProxyImpl(this._value);

  final DeletedRoutine _value;

  @override
  DeletedRoutine deleted(String deleted) => call(deleted: deleted);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DeletedRoutine(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DeletedRoutine(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  DeletedRoutine call({Object? deleted = const $CopyWithPlaceholder()}) {
    return DeletedRoutine(
      deleted: deleted == const $CopyWithPlaceholder() || deleted == null
          ? _value.deleted
          // ignore: cast_nullable_to_non_nullable
          : deleted as String,
    );
  }
}

extension $DeletedRoutineCopyWith on DeletedRoutine {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfDeletedRoutine.copyWith(...)` or `instanceOfDeletedRoutine.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$DeletedRoutineCWProxy get copyWith => _$DeletedRoutineCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeletedRoutine _$DeletedRoutineFromJson(Map<String, dynamic> json) =>
    $checkedCreate('DeletedRoutine', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['deleted']);
      final val = DeletedRoutine(
        deleted: $checkedConvert('deleted', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$DeletedRoutineToJson(DeletedRoutine instance) =>
    <String, dynamic>{'deleted': instance.deleted};
