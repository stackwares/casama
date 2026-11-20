// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'delete_mail_messages_result.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$DeleteMailMessagesResultCWProxy {
  DeleteMailMessagesResult deleted(int deleted);

  DeleteMailMessagesResult freed(int freed);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DeleteMailMessagesResult(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DeleteMailMessagesResult(...).copyWith(id: 12, name: "My name")
  /// ```
  DeleteMailMessagesResult call({int deleted, int freed});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfDeleteMailMessagesResult.copyWith(...)` or call `instanceOfDeleteMailMessagesResult.copyWith.fieldName(value)` for a single field.
class _$DeleteMailMessagesResultCWProxyImpl
    implements _$DeleteMailMessagesResultCWProxy {
  const _$DeleteMailMessagesResultCWProxyImpl(this._value);

  final DeleteMailMessagesResult _value;

  @override
  DeleteMailMessagesResult deleted(int deleted) => call(deleted: deleted);

  @override
  DeleteMailMessagesResult freed(int freed) => call(freed: freed);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DeleteMailMessagesResult(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DeleteMailMessagesResult(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  DeleteMailMessagesResult call({
    Object? deleted = const $CopyWithPlaceholder(),
    Object? freed = const $CopyWithPlaceholder(),
  }) {
    return DeleteMailMessagesResult(
      deleted: deleted == const $CopyWithPlaceholder() || deleted == null
          ? _value.deleted
          // ignore: cast_nullable_to_non_nullable
          : deleted as int,
      freed: freed == const $CopyWithPlaceholder() || freed == null
          ? _value.freed
          // ignore: cast_nullable_to_non_nullable
          : freed as int,
    );
  }
}

extension $DeleteMailMessagesResultCopyWith on DeleteMailMessagesResult {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfDeleteMailMessagesResult.copyWith(...)` or `instanceOfDeleteMailMessagesResult.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$DeleteMailMessagesResultCWProxy get copyWith =>
      _$DeleteMailMessagesResultCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeleteMailMessagesResult _$DeleteMailMessagesResultFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('DeleteMailMessagesResult', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['deleted', 'freed']);
  final val = DeleteMailMessagesResult(
    deleted: $checkedConvert('deleted', (v) => (v as num).toInt()),
    freed: $checkedConvert('freed', (v) => (v as num).toInt()),
  );
  return val;
});

Map<String, dynamic> _$DeleteMailMessagesResultToJson(
  DeleteMailMessagesResult instance,
) => <String, dynamic>{'deleted': instance.deleted, 'freed': instance.freed};
