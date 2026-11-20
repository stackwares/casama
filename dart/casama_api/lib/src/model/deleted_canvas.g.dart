// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'deleted_canvas.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$DeletedCanvasCWProxy {
  DeletedCanvas deleted(String deleted);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DeletedCanvas(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DeletedCanvas(...).copyWith(id: 12, name: "My name")
  /// ```
  DeletedCanvas call({String deleted});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfDeletedCanvas.copyWith(...)` or call `instanceOfDeletedCanvas.copyWith.fieldName(value)` for a single field.
class _$DeletedCanvasCWProxyImpl implements _$DeletedCanvasCWProxy {
  const _$DeletedCanvasCWProxyImpl(this._value);

  final DeletedCanvas _value;

  @override
  DeletedCanvas deleted(String deleted) => call(deleted: deleted);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DeletedCanvas(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DeletedCanvas(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  DeletedCanvas call({Object? deleted = const $CopyWithPlaceholder()}) {
    return DeletedCanvas(
      deleted: deleted == const $CopyWithPlaceholder() || deleted == null
          ? _value.deleted
          // ignore: cast_nullable_to_non_nullable
          : deleted as String,
    );
  }
}

extension $DeletedCanvasCopyWith on DeletedCanvas {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfDeletedCanvas.copyWith(...)` or `instanceOfDeletedCanvas.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$DeletedCanvasCWProxy get copyWith => _$DeletedCanvasCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeletedCanvas _$DeletedCanvasFromJson(Map<String, dynamic> json) =>
    $checkedCreate('DeletedCanvas', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['deleted']);
      final val = DeletedCanvas(
        deleted: $checkedConvert('deleted', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$DeletedCanvasToJson(DeletedCanvas instance) =>
    <String, dynamic>{'deleted': instance.deleted};
