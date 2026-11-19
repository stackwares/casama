// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'deleted_watch_key.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$DeletedWatchKeyCWProxy {
  DeletedWatchKey deleted(String deleted);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DeletedWatchKey(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DeletedWatchKey(...).copyWith(id: 12, name: "My name")
  /// ```
  DeletedWatchKey call({String deleted});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfDeletedWatchKey.copyWith(...)` or call `instanceOfDeletedWatchKey.copyWith.fieldName(value)` for a single field.
class _$DeletedWatchKeyCWProxyImpl implements _$DeletedWatchKeyCWProxy {
  const _$DeletedWatchKeyCWProxyImpl(this._value);

  final DeletedWatchKey _value;

  @override
  DeletedWatchKey deleted(String deleted) => call(deleted: deleted);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DeletedWatchKey(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DeletedWatchKey(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  DeletedWatchKey call({Object? deleted = const $CopyWithPlaceholder()}) {
    return DeletedWatchKey(
      deleted: deleted == const $CopyWithPlaceholder() || deleted == null
          ? _value.deleted
          // ignore: cast_nullable_to_non_nullable
          : deleted as String,
    );
  }
}

extension $DeletedWatchKeyCopyWith on DeletedWatchKey {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfDeletedWatchKey.copyWith(...)` or `instanceOfDeletedWatchKey.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$DeletedWatchKeyCWProxy get copyWith => _$DeletedWatchKeyCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeletedWatchKey _$DeletedWatchKeyFromJson(Map<String, dynamic> json) =>
    $checkedCreate('DeletedWatchKey', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['deleted']);
      final val = DeletedWatchKey(
        deleted: $checkedConvert('deleted', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$DeletedWatchKeyToJson(DeletedWatchKey instance) =>
    <String, dynamic>{'deleted': instance.deleted};
