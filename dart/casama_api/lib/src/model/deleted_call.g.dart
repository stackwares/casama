// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'deleted_call.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$DeletedCallCWProxy {
  DeletedCall deleted(int deleted);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DeletedCall(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DeletedCall(...).copyWith(id: 12, name: "My name")
  /// ```
  DeletedCall call({int deleted});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfDeletedCall.copyWith(...)` or call `instanceOfDeletedCall.copyWith.fieldName(value)` for a single field.
class _$DeletedCallCWProxyImpl implements _$DeletedCallCWProxy {
  const _$DeletedCallCWProxyImpl(this._value);

  final DeletedCall _value;

  @override
  DeletedCall deleted(int deleted) => call(deleted: deleted);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DeletedCall(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DeletedCall(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  DeletedCall call({Object? deleted = const $CopyWithPlaceholder()}) {
    return DeletedCall(
      deleted: deleted == const $CopyWithPlaceholder() || deleted == null
          ? _value.deleted
          // ignore: cast_nullable_to_non_nullable
          : deleted as int,
    );
  }
}

extension $DeletedCallCopyWith on DeletedCall {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfDeletedCall.copyWith(...)` or `instanceOfDeletedCall.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$DeletedCallCWProxy get copyWith => _$DeletedCallCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeletedCall _$DeletedCallFromJson(Map<String, dynamic> json) =>
    $checkedCreate('DeletedCall', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['deleted']);
      final val = DeletedCall(
        deleted: $checkedConvert('deleted', (v) => (v as num).toInt()),
      );
      return val;
    });

Map<String, dynamic> _$DeletedCallToJson(DeletedCall instance) =>
    <String, dynamic>{'deleted': instance.deleted};
