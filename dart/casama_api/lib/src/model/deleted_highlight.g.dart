// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'deleted_highlight.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$DeletedHighlightCWProxy {
  DeletedHighlight deleted(String deleted);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DeletedHighlight(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DeletedHighlight(...).copyWith(id: 12, name: "My name")
  /// ```
  DeletedHighlight call({String deleted});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfDeletedHighlight.copyWith(...)` or call `instanceOfDeletedHighlight.copyWith.fieldName(value)` for a single field.
class _$DeletedHighlightCWProxyImpl implements _$DeletedHighlightCWProxy {
  const _$DeletedHighlightCWProxyImpl(this._value);

  final DeletedHighlight _value;

  @override
  DeletedHighlight deleted(String deleted) => call(deleted: deleted);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DeletedHighlight(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DeletedHighlight(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  DeletedHighlight call({Object? deleted = const $CopyWithPlaceholder()}) {
    return DeletedHighlight(
      deleted: deleted == const $CopyWithPlaceholder() || deleted == null
          ? _value.deleted
          // ignore: cast_nullable_to_non_nullable
          : deleted as String,
    );
  }
}

extension $DeletedHighlightCopyWith on DeletedHighlight {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfDeletedHighlight.copyWith(...)` or `instanceOfDeletedHighlight.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$DeletedHighlightCWProxy get copyWith => _$DeletedHighlightCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeletedHighlight _$DeletedHighlightFromJson(Map<String, dynamic> json) =>
    $checkedCreate('DeletedHighlight', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['deleted']);
      final val = DeletedHighlight(
        deleted: $checkedConvert('deleted', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$DeletedHighlightToJson(DeletedHighlight instance) =>
    <String, dynamic>{'deleted': instance.deleted};
