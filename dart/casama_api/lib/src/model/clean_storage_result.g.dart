// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'clean_storage_result.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CleanStorageResultCWProxy {
  CleanStorageResult freedBytes(int freedBytes);

  CleanStorageResult storage(ComputerStorage storage);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CleanStorageResult(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CleanStorageResult(...).copyWith(id: 12, name: "My name")
  /// ```
  CleanStorageResult call({int freedBytes, ComputerStorage storage});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfCleanStorageResult.copyWith(...)` or call `instanceOfCleanStorageResult.copyWith.fieldName(value)` for a single field.
class _$CleanStorageResultCWProxyImpl implements _$CleanStorageResultCWProxy {
  const _$CleanStorageResultCWProxyImpl(this._value);

  final CleanStorageResult _value;

  @override
  CleanStorageResult freedBytes(int freedBytes) => call(freedBytes: freedBytes);

  @override
  CleanStorageResult storage(ComputerStorage storage) => call(storage: storage);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CleanStorageResult(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CleanStorageResult(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  CleanStorageResult call({
    Object? freedBytes = const $CopyWithPlaceholder(),
    Object? storage = const $CopyWithPlaceholder(),
  }) {
    return CleanStorageResult(
      freedBytes:
          freedBytes == const $CopyWithPlaceholder() || freedBytes == null
          ? _value.freedBytes
          // ignore: cast_nullable_to_non_nullable
          : freedBytes as int,
      storage: storage == const $CopyWithPlaceholder() || storage == null
          ? _value.storage
          // ignore: cast_nullable_to_non_nullable
          : storage as ComputerStorage,
    );
  }
}

extension $CleanStorageResultCopyWith on CleanStorageResult {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfCleanStorageResult.copyWith(...)` or `instanceOfCleanStorageResult.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CleanStorageResultCWProxy get copyWith =>
      _$CleanStorageResultCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CleanStorageResult _$CleanStorageResultFromJson(Map<String, dynamic> json) =>
    $checkedCreate('CleanStorageResult', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['freed_bytes', 'storage']);
      final val = CleanStorageResult(
        freedBytes: $checkedConvert('freed_bytes', (v) => (v as num).toInt()),
        storage: $checkedConvert(
          'storage',
          (v) => ComputerStorage.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    }, fieldKeyMap: const {'freedBytes': 'freed_bytes'});

Map<String, dynamic> _$CleanStorageResultToJson(CleanStorageResult instance) =>
    <String, dynamic>{
      'freed_bytes': instance.freedBytes,
      'storage': instance.storage.toJson(),
    };
