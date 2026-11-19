// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'deleted_watch_keys.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$DeletedWatchKeysCWProxy {
  DeletedWatchKeys deleted(int deleted);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DeletedWatchKeys(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DeletedWatchKeys(...).copyWith(id: 12, name: "My name")
  /// ```
  DeletedWatchKeys call({int deleted});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfDeletedWatchKeys.copyWith(...)` or call `instanceOfDeletedWatchKeys.copyWith.fieldName(value)` for a single field.
class _$DeletedWatchKeysCWProxyImpl implements _$DeletedWatchKeysCWProxy {
  const _$DeletedWatchKeysCWProxyImpl(this._value);

  final DeletedWatchKeys _value;

  @override
  DeletedWatchKeys deleted(int deleted) => call(deleted: deleted);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DeletedWatchKeys(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DeletedWatchKeys(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  DeletedWatchKeys call({Object? deleted = const $CopyWithPlaceholder()}) {
    return DeletedWatchKeys(
      deleted: deleted == const $CopyWithPlaceholder() || deleted == null
          ? _value.deleted
          // ignore: cast_nullable_to_non_nullable
          : deleted as int,
    );
  }
}

extension $DeletedWatchKeysCopyWith on DeletedWatchKeys {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfDeletedWatchKeys.copyWith(...)` or `instanceOfDeletedWatchKeys.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$DeletedWatchKeysCWProxy get copyWith => _$DeletedWatchKeysCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeletedWatchKeys _$DeletedWatchKeysFromJson(Map<String, dynamic> json) =>
    $checkedCreate('DeletedWatchKeys', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['deleted']);
      final val = DeletedWatchKeys(
        deleted: $checkedConvert('deleted', (v) => (v as num).toInt()),
      );
      return val;
    });

Map<String, dynamic> _$DeletedWatchKeysToJson(DeletedWatchKeys instance) =>
    <String, dynamic>{'deleted': instance.deleted};
