// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'computer_storage.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ComputerStorageCWProxy {
  ComputerStorage usedBytes(int usedBytes);

  ComputerStorage limitBytes(int limitBytes);

  ComputerStorage categories(List<StorageCategory> categories);

  ComputerStorage cleanableBytes(int cleanableBytes);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ComputerStorage(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ComputerStorage(...).copyWith(id: 12, name: "My name")
  /// ```
  ComputerStorage call({
    int usedBytes,
    int limitBytes,
    List<StorageCategory> categories,
    int cleanableBytes,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfComputerStorage.copyWith(...)` or call `instanceOfComputerStorage.copyWith.fieldName(value)` for a single field.
class _$ComputerStorageCWProxyImpl implements _$ComputerStorageCWProxy {
  const _$ComputerStorageCWProxyImpl(this._value);

  final ComputerStorage _value;

  @override
  ComputerStorage usedBytes(int usedBytes) => call(usedBytes: usedBytes);

  @override
  ComputerStorage limitBytes(int limitBytes) => call(limitBytes: limitBytes);

  @override
  ComputerStorage categories(List<StorageCategory> categories) =>
      call(categories: categories);

  @override
  ComputerStorage cleanableBytes(int cleanableBytes) =>
      call(cleanableBytes: cleanableBytes);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ComputerStorage(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ComputerStorage(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ComputerStorage call({
    Object? usedBytes = const $CopyWithPlaceholder(),
    Object? limitBytes = const $CopyWithPlaceholder(),
    Object? categories = const $CopyWithPlaceholder(),
    Object? cleanableBytes = const $CopyWithPlaceholder(),
  }) {
    return ComputerStorage(
      usedBytes: usedBytes == const $CopyWithPlaceholder() || usedBytes == null
          ? _value.usedBytes
          // ignore: cast_nullable_to_non_nullable
          : usedBytes as int,
      limitBytes:
          limitBytes == const $CopyWithPlaceholder() || limitBytes == null
          ? _value.limitBytes
          // ignore: cast_nullable_to_non_nullable
          : limitBytes as int,
      categories:
          categories == const $CopyWithPlaceholder() || categories == null
          ? _value.categories
          // ignore: cast_nullable_to_non_nullable
          : categories as List<StorageCategory>,
      cleanableBytes:
          cleanableBytes == const $CopyWithPlaceholder() ||
              cleanableBytes == null
          ? _value.cleanableBytes
          // ignore: cast_nullable_to_non_nullable
          : cleanableBytes as int,
    );
  }
}

extension $ComputerStorageCopyWith on ComputerStorage {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfComputerStorage.copyWith(...)` or `instanceOfComputerStorage.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ComputerStorageCWProxy get copyWith => _$ComputerStorageCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ComputerStorage _$ComputerStorageFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'ComputerStorage',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'used_bytes',
            'limit_bytes',
            'categories',
            'cleanable_bytes',
          ],
        );
        final val = ComputerStorage(
          usedBytes: $checkedConvert('used_bytes', (v) => (v as num).toInt()),
          limitBytes: $checkedConvert('limit_bytes', (v) => (v as num).toInt()),
          categories: $checkedConvert(
            'categories',
            (v) => (v as List<dynamic>)
                .map((e) => StorageCategory.fromJson(e as Map<String, dynamic>))
                .toList(),
          ),
          cleanableBytes: $checkedConvert(
            'cleanable_bytes',
            (v) => (v as num).toInt(),
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'usedBytes': 'used_bytes',
        'limitBytes': 'limit_bytes',
        'cleanableBytes': 'cleanable_bytes',
      },
    );

Map<String, dynamic> _$ComputerStorageToJson(ComputerStorage instance) =>
    <String, dynamic>{
      'used_bytes': instance.usedBytes,
      'limit_bytes': instance.limitBytes,
      'categories': instance.categories.map((e) => e.toJson()).toList(),
      'cleanable_bytes': instance.cleanableBytes,
    };
