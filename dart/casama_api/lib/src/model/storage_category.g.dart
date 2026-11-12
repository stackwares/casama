// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'storage_category.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$StorageCategoryCWProxy {
  StorageCategory id(StorageCategoryIdEnum id);

  StorageCategory bytes(int bytes);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `StorageCategory(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// StorageCategory(...).copyWith(id: 12, name: "My name")
  /// ```
  StorageCategory call({StorageCategoryIdEnum id, int bytes});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfStorageCategory.copyWith(...)` or call `instanceOfStorageCategory.copyWith.fieldName(value)` for a single field.
class _$StorageCategoryCWProxyImpl implements _$StorageCategoryCWProxy {
  const _$StorageCategoryCWProxyImpl(this._value);

  final StorageCategory _value;

  @override
  StorageCategory id(StorageCategoryIdEnum id) => call(id: id);

  @override
  StorageCategory bytes(int bytes) => call(bytes: bytes);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `StorageCategory(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// StorageCategory(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  StorageCategory call({
    Object? id = const $CopyWithPlaceholder(),
    Object? bytes = const $CopyWithPlaceholder(),
  }) {
    return StorageCategory(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as StorageCategoryIdEnum,
      bytes: bytes == const $CopyWithPlaceholder() || bytes == null
          ? _value.bytes
          // ignore: cast_nullable_to_non_nullable
          : bytes as int,
    );
  }
}

extension $StorageCategoryCopyWith on StorageCategory {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfStorageCategory.copyWith(...)` or `instanceOfStorageCategory.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$StorageCategoryCWProxy get copyWith => _$StorageCategoryCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StorageCategory _$StorageCategoryFromJson(Map<String, dynamic> json) =>
    $checkedCreate('StorageCategory', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['id', 'bytes']);
      final val = StorageCategory(
        id: $checkedConvert(
          'id',
          (v) => $enumDecode(_$StorageCategoryIdEnumEnumMap, v),
        ),
        bytes: $checkedConvert('bytes', (v) => (v as num).toInt()),
      );
      return val;
    });

Map<String, dynamic> _$StorageCategoryToJson(StorageCategory instance) =>
    <String, dynamic>{
      'id': _$StorageCategoryIdEnumEnumMap[instance.id]!,
      'bytes': instance.bytes,
    };

const _$StorageCategoryIdEnumEnumMap = {
  StorageCategoryIdEnum.files: 'files',
  StorageCategoryIdEnum.apps: 'apps',
  StorageCategoryIdEnum.caches: 'caches',
  StorageCategoryIdEnum.browser: 'browser',
  StorageCategoryIdEnum.other: 'other',
};
