// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'deleted_knowledge_source.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$DeletedKnowledgeSourceCWProxy {
  DeletedKnowledgeSource deleted(String deleted);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DeletedKnowledgeSource(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DeletedKnowledgeSource(...).copyWith(id: 12, name: "My name")
  /// ```
  DeletedKnowledgeSource call({String deleted});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfDeletedKnowledgeSource.copyWith(...)` or call `instanceOfDeletedKnowledgeSource.copyWith.fieldName(value)` for a single field.
class _$DeletedKnowledgeSourceCWProxyImpl
    implements _$DeletedKnowledgeSourceCWProxy {
  const _$DeletedKnowledgeSourceCWProxyImpl(this._value);

  final DeletedKnowledgeSource _value;

  @override
  DeletedKnowledgeSource deleted(String deleted) => call(deleted: deleted);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DeletedKnowledgeSource(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DeletedKnowledgeSource(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  DeletedKnowledgeSource call({
    Object? deleted = const $CopyWithPlaceholder(),
  }) {
    return DeletedKnowledgeSource(
      deleted: deleted == const $CopyWithPlaceholder() || deleted == null
          ? _value.deleted
          // ignore: cast_nullable_to_non_nullable
          : deleted as String,
    );
  }
}

extension $DeletedKnowledgeSourceCopyWith on DeletedKnowledgeSource {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfDeletedKnowledgeSource.copyWith(...)` or `instanceOfDeletedKnowledgeSource.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$DeletedKnowledgeSourceCWProxy get copyWith =>
      _$DeletedKnowledgeSourceCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeletedKnowledgeSource _$DeletedKnowledgeSourceFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('DeletedKnowledgeSource', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['deleted']);
  final val = DeletedKnowledgeSource(
    deleted: $checkedConvert('deleted', (v) => v as String),
  );
  return val;
});

Map<String, dynamic> _$DeletedKnowledgeSourceToJson(
  DeletedKnowledgeSource instance,
) => <String, dynamic>{'deleted': instance.deleted};
