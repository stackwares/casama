// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'upload_result.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$UploadResultCWProxy {
  UploadResult path(String path);

  UploadResult size(int size);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `UploadResult(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// UploadResult(...).copyWith(id: 12, name: "My name")
  /// ````
  UploadResult call({String path, int size});
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfUploadResult.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfUploadResult.copyWith.fieldName(...)`
class _$UploadResultCWProxyImpl implements _$UploadResultCWProxy {
  const _$UploadResultCWProxyImpl(this._value);

  final UploadResult _value;

  @override
  UploadResult path(String path) => this(path: path);

  @override
  UploadResult size(int size) => this(size: size);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `UploadResult(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// UploadResult(...).copyWith(id: 12, name: "My name")
  /// ````
  UploadResult call({
    Object? path = const $CopyWithPlaceholder(),
    Object? size = const $CopyWithPlaceholder(),
  }) {
    return UploadResult(
      path: path == const $CopyWithPlaceholder()
          ? _value.path
          // ignore: cast_nullable_to_non_nullable
          : path as String,
      size: size == const $CopyWithPlaceholder()
          ? _value.size
          // ignore: cast_nullable_to_non_nullable
          : size as int,
    );
  }
}

extension $UploadResultCopyWith on UploadResult {
  /// Returns a callable class that can be used as follows: `instanceOfUploadResult.copyWith(...)` or like so:`instanceOfUploadResult.copyWith.fieldName(...)`.
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
