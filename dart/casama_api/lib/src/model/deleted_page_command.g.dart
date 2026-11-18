// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'deleted_page_command.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$DeletedPageCommandCWProxy {
  DeletedPageCommand deleted(String deleted);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DeletedPageCommand(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DeletedPageCommand(...).copyWith(id: 12, name: "My name")
  /// ```
  DeletedPageCommand call({String deleted});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfDeletedPageCommand.copyWith(...)` or call `instanceOfDeletedPageCommand.copyWith.fieldName(value)` for a single field.
class _$DeletedPageCommandCWProxyImpl implements _$DeletedPageCommandCWProxy {
  const _$DeletedPageCommandCWProxyImpl(this._value);

  final DeletedPageCommand _value;

  @override
  DeletedPageCommand deleted(String deleted) => call(deleted: deleted);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DeletedPageCommand(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DeletedPageCommand(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  DeletedPageCommand call({Object? deleted = const $CopyWithPlaceholder()}) {
    return DeletedPageCommand(
      deleted: deleted == const $CopyWithPlaceholder() || deleted == null
          ? _value.deleted
          // ignore: cast_nullable_to_non_nullable
          : deleted as String,
    );
  }
}

extension $DeletedPageCommandCopyWith on DeletedPageCommand {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfDeletedPageCommand.copyWith(...)` or `instanceOfDeletedPageCommand.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$DeletedPageCommandCWProxy get copyWith =>
      _$DeletedPageCommandCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeletedPageCommand _$DeletedPageCommandFromJson(Map<String, dynamic> json) =>
    $checkedCreate('DeletedPageCommand', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['deleted']);
      final val = DeletedPageCommand(
        deleted: $checkedConvert('deleted', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$DeletedPageCommandToJson(DeletedPageCommand instance) =>
    <String, dynamic>{'deleted': instance.deleted};
