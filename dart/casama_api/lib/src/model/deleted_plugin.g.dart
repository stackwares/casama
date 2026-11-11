// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'deleted_plugin.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$DeletedPluginCWProxy {
  DeletedPlugin deleted(String deleted);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DeletedPlugin(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DeletedPlugin(...).copyWith(id: 12, name: "My name")
  /// ```
  DeletedPlugin call({String deleted});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfDeletedPlugin.copyWith(...)` or call `instanceOfDeletedPlugin.copyWith.fieldName(value)` for a single field.
class _$DeletedPluginCWProxyImpl implements _$DeletedPluginCWProxy {
  const _$DeletedPluginCWProxyImpl(this._value);

  final DeletedPlugin _value;

  @override
  DeletedPlugin deleted(String deleted) => call(deleted: deleted);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `DeletedPlugin(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// DeletedPlugin(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  DeletedPlugin call({Object? deleted = const $CopyWithPlaceholder()}) {
    return DeletedPlugin(
      deleted: deleted == const $CopyWithPlaceholder() || deleted == null
          ? _value.deleted
          // ignore: cast_nullable_to_non_nullable
          : deleted as String,
    );
  }
}

extension $DeletedPluginCopyWith on DeletedPlugin {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfDeletedPlugin.copyWith(...)` or `instanceOfDeletedPlugin.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$DeletedPluginCWProxy get copyWith => _$DeletedPluginCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeletedPlugin _$DeletedPluginFromJson(Map<String, dynamic> json) =>
    $checkedCreate('DeletedPlugin', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['deleted']);
      final val = DeletedPlugin(
        deleted: $checkedConvert('deleted', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$DeletedPluginToJson(DeletedPlugin instance) =>
    <String, dynamic>{'deleted': instance.deleted};
