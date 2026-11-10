// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'deleted_password_manager.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$DeletedPasswordManagerCWProxy {
  DeletedPasswordManager deleted(String deleted);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DeletedPasswordManager(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DeletedPasswordManager(...).copyWith(id: 12, name: "My name")
  /// ```
  DeletedPasswordManager call({String deleted});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfDeletedPasswordManager.copyWith(...)` or call `instanceOfDeletedPasswordManager.copyWith.fieldName(value)` for a single field.
class _$DeletedPasswordManagerCWProxyImpl
    implements _$DeletedPasswordManagerCWProxy {
  const _$DeletedPasswordManagerCWProxyImpl(this._value);

  final DeletedPasswordManager _value;

  @override
  DeletedPasswordManager deleted(String deleted) => call(deleted: deleted);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DeletedPasswordManager(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DeletedPasswordManager(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  DeletedPasswordManager call({
    Object? deleted = const $CopyWithPlaceholder(),
  }) {
    return DeletedPasswordManager(
      deleted: deleted == const $CopyWithPlaceholder() || deleted == null
          ? _value.deleted
          // ignore: cast_nullable_to_non_nullable
          : deleted as String,
    );
  }
}

extension $DeletedPasswordManagerCopyWith on DeletedPasswordManager {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfDeletedPasswordManager.copyWith(...)` or `instanceOfDeletedPasswordManager.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$DeletedPasswordManagerCWProxy get copyWith =>
      _$DeletedPasswordManagerCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeletedPasswordManager _$DeletedPasswordManagerFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('DeletedPasswordManager', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['deleted']);
  final val = DeletedPasswordManager(
    deleted: $checkedConvert('deleted', (v) => v as String),
  );
  return val;
});

Map<String, dynamic> _$DeletedPasswordManagerToJson(
  DeletedPasswordManager instance,
) => <String, dynamic>{'deleted': instance.deleted};
