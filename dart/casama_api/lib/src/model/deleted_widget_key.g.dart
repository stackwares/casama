// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'deleted_widget_key.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$DeletedWidgetKeyCWProxy {
  DeletedWidgetKey deleted(String deleted);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DeletedWidgetKey(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DeletedWidgetKey(...).copyWith(id: 12, name: "My name")
  /// ```
  DeletedWidgetKey call({String deleted});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfDeletedWidgetKey.copyWith(...)` or call `instanceOfDeletedWidgetKey.copyWith.fieldName(value)` for a single field.
class _$DeletedWidgetKeyCWProxyImpl implements _$DeletedWidgetKeyCWProxy {
  const _$DeletedWidgetKeyCWProxyImpl(this._value);

  final DeletedWidgetKey _value;

  @override
  DeletedWidgetKey deleted(String deleted) => call(deleted: deleted);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DeletedWidgetKey(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DeletedWidgetKey(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  DeletedWidgetKey call({Object? deleted = const $CopyWithPlaceholder()}) {
    return DeletedWidgetKey(
      deleted: deleted == const $CopyWithPlaceholder() || deleted == null
          ? _value.deleted
          // ignore: cast_nullable_to_non_nullable
          : deleted as String,
    );
  }
}

extension $DeletedWidgetKeyCopyWith on DeletedWidgetKey {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfDeletedWidgetKey.copyWith(...)` or `instanceOfDeletedWidgetKey.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$DeletedWidgetKeyCWProxy get copyWith => _$DeletedWidgetKeyCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeletedWidgetKey _$DeletedWidgetKeyFromJson(Map<String, dynamic> json) =>
    $checkedCreate('DeletedWidgetKey', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['deleted']);
      final val = DeletedWidgetKey(
        deleted: $checkedConvert('deleted', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$DeletedWidgetKeyToJson(DeletedWidgetKey instance) =>
    <String, dynamic>{'deleted': instance.deleted};
