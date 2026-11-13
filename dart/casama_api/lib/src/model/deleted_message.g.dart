// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'deleted_message.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$DeletedMessageCWProxy {
  DeletedMessage deleted(String deleted);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DeletedMessage(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DeletedMessage(...).copyWith(id: 12, name: "My name")
  /// ```
  DeletedMessage call({String deleted});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfDeletedMessage.copyWith(...)` or call `instanceOfDeletedMessage.copyWith.fieldName(value)` for a single field.
class _$DeletedMessageCWProxyImpl implements _$DeletedMessageCWProxy {
  const _$DeletedMessageCWProxyImpl(this._value);

  final DeletedMessage _value;

  @override
  DeletedMessage deleted(String deleted) => call(deleted: deleted);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DeletedMessage(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DeletedMessage(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  DeletedMessage call({Object? deleted = const $CopyWithPlaceholder()}) {
    return DeletedMessage(
      deleted: deleted == const $CopyWithPlaceholder() || deleted == null
          ? _value.deleted
          // ignore: cast_nullable_to_non_nullable
          : deleted as String,
    );
  }
}

extension $DeletedMessageCopyWith on DeletedMessage {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfDeletedMessage.copyWith(...)` or `instanceOfDeletedMessage.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$DeletedMessageCWProxy get copyWith => _$DeletedMessageCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeletedMessage _$DeletedMessageFromJson(Map<String, dynamic> json) =>
    $checkedCreate('DeletedMessage', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['deleted']);
      final val = DeletedMessage(
        deleted: $checkedConvert('deleted', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$DeletedMessageToJson(DeletedMessage instance) =>
    <String, dynamic>{'deleted': instance.deleted};
