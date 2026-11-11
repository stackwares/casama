// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'deleted_user_fact.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$DeletedUserFactCWProxy {
  DeletedUserFact deleted(String deleted);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DeletedUserFact(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DeletedUserFact(...).copyWith(id: 12, name: "My name")
  /// ```
  DeletedUserFact call({String deleted});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfDeletedUserFact.copyWith(...)` or call `instanceOfDeletedUserFact.copyWith.fieldName(value)` for a single field.
class _$DeletedUserFactCWProxyImpl implements _$DeletedUserFactCWProxy {
  const _$DeletedUserFactCWProxyImpl(this._value);

  final DeletedUserFact _value;

  @override
  DeletedUserFact deleted(String deleted) => call(deleted: deleted);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DeletedUserFact(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DeletedUserFact(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  DeletedUserFact call({Object? deleted = const $CopyWithPlaceholder()}) {
    return DeletedUserFact(
      deleted: deleted == const $CopyWithPlaceholder() || deleted == null
          ? _value.deleted
          // ignore: cast_nullable_to_non_nullable
          : deleted as String,
    );
  }
}

extension $DeletedUserFactCopyWith on DeletedUserFact {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfDeletedUserFact.copyWith(...)` or `instanceOfDeletedUserFact.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$DeletedUserFactCWProxy get copyWith => _$DeletedUserFactCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeletedUserFact _$DeletedUserFactFromJson(Map<String, dynamic> json) =>
    $checkedCreate('DeletedUserFact', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['deleted']);
      final val = DeletedUserFact(
        deleted: $checkedConvert('deleted', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$DeletedUserFactToJson(DeletedUserFact instance) =>
    <String, dynamic>{'deleted': instance.deleted};
