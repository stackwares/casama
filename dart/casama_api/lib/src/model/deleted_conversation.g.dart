// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'deleted_conversation.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$DeletedConversationCWProxy {
  DeletedConversation deleted(String deleted);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DeletedConversation(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DeletedConversation(...).copyWith(id: 12, name: "My name")
  /// ```
  DeletedConversation call({String deleted});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfDeletedConversation.copyWith(...)` or call `instanceOfDeletedConversation.copyWith.fieldName(value)` for a single field.
class _$DeletedConversationCWProxyImpl implements _$DeletedConversationCWProxy {
  const _$DeletedConversationCWProxyImpl(this._value);

  final DeletedConversation _value;

  @override
  DeletedConversation deleted(String deleted) => call(deleted: deleted);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DeletedConversation(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DeletedConversation(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  DeletedConversation call({Object? deleted = const $CopyWithPlaceholder()}) {
    return DeletedConversation(
      deleted: deleted == const $CopyWithPlaceholder() || deleted == null
          ? _value.deleted
          // ignore: cast_nullable_to_non_nullable
          : deleted as String,
    );
  }
}

extension $DeletedConversationCopyWith on DeletedConversation {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfDeletedConversation.copyWith(...)` or `instanceOfDeletedConversation.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$DeletedConversationCWProxy get copyWith =>
      _$DeletedConversationCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeletedConversation _$DeletedConversationFromJson(Map<String, dynamic> json) =>
    $checkedCreate('DeletedConversation', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['deleted']);
      final val = DeletedConversation(
        deleted: $checkedConvert('deleted', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$DeletedConversationToJson(
  DeletedConversation instance,
) => <String, dynamic>{'deleted': instance.deleted};
