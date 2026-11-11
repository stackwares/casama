// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'delete_result.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$DeleteResultCWProxy {
  DeleteResult deleted(String deleted);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DeleteResult(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DeleteResult(...).copyWith(id: 12, name: "My name")
  /// ```
  DeleteResult call({String deleted});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfDeleteResult.copyWith(...)` or call `instanceOfDeleteResult.copyWith.fieldName(value)` for a single field.
class _$DeleteResultCWProxyImpl implements _$DeleteResultCWProxy {
  const _$DeleteResultCWProxyImpl(this._value);

  final DeleteResult _value;

  @override
  DeleteResult deleted(String deleted) => call(deleted: deleted);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DeleteResult(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DeleteResult(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  DeleteResult call({Object? deleted = const $CopyWithPlaceholder()}) {
    return DeleteResult(
      deleted: deleted == const $CopyWithPlaceholder() || deleted == null
          ? _value.deleted
          // ignore: cast_nullable_to_non_nullable
          : deleted as String,
    );
  }
}

extension $DeleteResultCopyWith on DeleteResult {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfDeleteResult.copyWith(...)` or `instanceOfDeleteResult.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$DeleteResultCWProxy get copyWith => _$DeleteResultCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeleteResult _$DeleteResultFromJson(Map<String, dynamic> json) =>
    $checkedCreate('DeleteResult', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['deleted']);
      final val = DeleteResult(
        deleted: $checkedConvert('deleted', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$DeleteResultToJson(DeleteResult instance) =>
    <String, dynamic>{'deleted': instance.deleted};
