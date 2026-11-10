// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'deleted_watcher.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$DeletedWatcherCWProxy {
  DeletedWatcher deleted(String deleted);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DeletedWatcher(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DeletedWatcher(...).copyWith(id: 12, name: "My name")
  /// ```
  DeletedWatcher call({String deleted});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfDeletedWatcher.copyWith(...)` or call `instanceOfDeletedWatcher.copyWith.fieldName(value)` for a single field.
class _$DeletedWatcherCWProxyImpl implements _$DeletedWatcherCWProxy {
  const _$DeletedWatcherCWProxyImpl(this._value);

  final DeletedWatcher _value;

  @override
  DeletedWatcher deleted(String deleted) => call(deleted: deleted);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DeletedWatcher(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DeletedWatcher(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  DeletedWatcher call({Object? deleted = const $CopyWithPlaceholder()}) {
    return DeletedWatcher(
      deleted: deleted == const $CopyWithPlaceholder() || deleted == null
          ? _value.deleted
          // ignore: cast_nullable_to_non_nullable
          : deleted as String,
    );
  }
}

extension $DeletedWatcherCopyWith on DeletedWatcher {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfDeletedWatcher.copyWith(...)` or `instanceOfDeletedWatcher.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$DeletedWatcherCWProxy get copyWith => _$DeletedWatcherCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeletedWatcher _$DeletedWatcherFromJson(Map<String, dynamic> json) =>
    $checkedCreate('DeletedWatcher', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['deleted']);
      final val = DeletedWatcher(
        deleted: $checkedConvert('deleted', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$DeletedWatcherToJson(DeletedWatcher instance) =>
    <String, dynamic>{'deleted': instance.deleted};
