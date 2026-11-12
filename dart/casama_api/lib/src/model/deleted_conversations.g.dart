// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'deleted_conversations.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$DeletedConversationsCWProxy {
  DeletedConversations deleted(int deleted);

  DeletedConversations skipped(int skipped);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DeletedConversations(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DeletedConversations(...).copyWith(id: 12, name: "My name")
  /// ```
  DeletedConversations call({int deleted, int skipped});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfDeletedConversations.copyWith(...)` or call `instanceOfDeletedConversations.copyWith.fieldName(value)` for a single field.
class _$DeletedConversationsCWProxyImpl
    implements _$DeletedConversationsCWProxy {
  const _$DeletedConversationsCWProxyImpl(this._value);

  final DeletedConversations _value;

  @override
  DeletedConversations deleted(int deleted) => call(deleted: deleted);

  @override
  DeletedConversations skipped(int skipped) => call(skipped: skipped);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DeletedConversations(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DeletedConversations(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  DeletedConversations call({
    Object? deleted = const $CopyWithPlaceholder(),
    Object? skipped = const $CopyWithPlaceholder(),
  }) {
    return DeletedConversations(
      deleted: deleted == const $CopyWithPlaceholder() || deleted == null
          ? _value.deleted
          // ignore: cast_nullable_to_non_nullable
          : deleted as int,
      skipped: skipped == const $CopyWithPlaceholder() || skipped == null
          ? _value.skipped
          // ignore: cast_nullable_to_non_nullable
          : skipped as int,
    );
  }
}

extension $DeletedConversationsCopyWith on DeletedConversations {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfDeletedConversations.copyWith(...)` or `instanceOfDeletedConversations.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$DeletedConversationsCWProxy get copyWith =>
      _$DeletedConversationsCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeletedConversations _$DeletedConversationsFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('DeletedConversations', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['deleted', 'skipped']);
  final val = DeletedConversations(
    deleted: $checkedConvert('deleted', (v) => (v as num).toInt()),
    skipped: $checkedConvert('skipped', (v) => (v as num).toInt()),
  );
  return val;
});

Map<String, dynamic> _$DeletedConversationsToJson(
  DeletedConversations instance,
) => <String, dynamic>{
  'deleted': instance.deleted,
  'skipped': instance.skipped,
};
