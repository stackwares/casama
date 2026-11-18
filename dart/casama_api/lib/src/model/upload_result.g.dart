// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'upload_result.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$UploadResultCWProxy {
  UploadResult path(String path);

  UploadResult size(int size);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `UploadResult(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// UploadResult(...).copyWith(id: 12, name: "My name")
  /// ```
  UploadResult call({String path, int size});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfUploadResult.copyWith(...)` or call `instanceOfUploadResult.copyWith.fieldName(value)` for a single field.
class _$UploadResultCWProxyImpl implements _$UploadResultCWProxy {
  const _$UploadResultCWProxyImpl(this._value);

  final UploadResult _value;

  @override
  UploadResult path(String path) => call(path: path);

  @override
  UploadResult size(int size) => call(size: size);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `UploadResult(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// UploadResult(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  UploadResult call({
    Object? path = const $CopyWithPlaceholder(),
    Object? size = const $CopyWithPlaceholder(),
  }) {
    return UploadResult(
      path: path == const $CopyWithPlaceholder() || path == null
          ? _value.path
          // ignore: cast_nullable_to_non_nullable
          : path as String,
      size: size == const $CopyWithPlaceholder() || size == null
          ? _value.size
          // ignore: cast_nullable_to_non_nullable
          : size as int,
    );
  }
}

extension $UploadResultCopyWith on UploadResult {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfUploadResult.copyWith(...)` or `instanceOfUploadResult.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$UploadResultCWProxy get copyWith => _$UploadResultCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UploadResult _$UploadResultFromJson(Map<String, dynamic> json) =>
    $checkedCreate('UploadResult', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['path', 'size']);
      final val = UploadResult(
        path: $checkedConvert('path', (v) => v as String),
        size: $checkedConvert('size', (v) => (v as num).toInt()),
      );
      return val;
    });

Map<String, dynamic> _$UploadResultToJson(UploadResult instance) =>
    <String, dynamic>{'path': instance.path, 'size': instance.size};
