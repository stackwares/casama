// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'deleted_page.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$DeletedPageCWProxy {
  DeletedPage deleted(String deleted);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DeletedPage(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DeletedPage(...).copyWith(id: 12, name: "My name")
  /// ```
  DeletedPage call({String deleted});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfDeletedPage.copyWith(...)` or call `instanceOfDeletedPage.copyWith.fieldName(value)` for a single field.
class _$DeletedPageCWProxyImpl implements _$DeletedPageCWProxy {
  const _$DeletedPageCWProxyImpl(this._value);

  final DeletedPage _value;

  @override
  DeletedPage deleted(String deleted) => call(deleted: deleted);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DeletedPage(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DeletedPage(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  DeletedPage call({Object? deleted = const $CopyWithPlaceholder()}) {
    return DeletedPage(
      deleted: deleted == const $CopyWithPlaceholder() || deleted == null
          ? _value.deleted
          // ignore: cast_nullable_to_non_nullable
          : deleted as String,
    );
  }
}

extension $DeletedPageCopyWith on DeletedPage {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfDeletedPage.copyWith(...)` or `instanceOfDeletedPage.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$DeletedPageCWProxy get copyWith => _$DeletedPageCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeletedPage _$DeletedPageFromJson(Map<String, dynamic> json) =>
    $checkedCreate('DeletedPage', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['deleted']);
      final val = DeletedPage(
        deleted: $checkedConvert('deleted', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$DeletedPageToJson(DeletedPage instance) =>
    <String, dynamic>{'deleted': instance.deleted};
