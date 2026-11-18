// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pack_file_input.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PackFileInputCWProxy {
  PackFileInput path(String path);

  PackFileInput base64(String base64);

  PackFileInput executable(bool? executable);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PackFileInput(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PackFileInput(...).copyWith(id: 12, name: "My name")
  /// ```
  PackFileInput call({String path, String base64, bool? executable});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfPackFileInput.copyWith(...)` or call `instanceOfPackFileInput.copyWith.fieldName(value)` for a single field.
class _$PackFileInputCWProxyImpl implements _$PackFileInputCWProxy {
  const _$PackFileInputCWProxyImpl(this._value);

  final PackFileInput _value;

  @override
  PackFileInput path(String path) => call(path: path);

  @override
  PackFileInput base64(String base64) => call(base64: base64);

  @override
  PackFileInput executable(bool? executable) => call(executable: executable);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PackFileInput(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PackFileInput(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  PackFileInput call({
    Object? path = const $CopyWithPlaceholder(),
    Object? base64 = const $CopyWithPlaceholder(),
    Object? executable = const $CopyWithPlaceholder(),
  }) {
    return PackFileInput(
      path: path == const $CopyWithPlaceholder() || path == null
          ? _value.path
          // ignore: cast_nullable_to_non_nullable
          : path as String,
      base64: base64 == const $CopyWithPlaceholder() || base64 == null
          ? _value.base64
          // ignore: cast_nullable_to_non_nullable
          : base64 as String,
      executable: executable == const $CopyWithPlaceholder()
          ? _value.executable
          // ignore: cast_nullable_to_non_nullable
          : executable as bool?,
    );
  }
}

extension $PackFileInputCopyWith on PackFileInput {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfPackFileInput.copyWith(...)` or `instanceOfPackFileInput.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PackFileInputCWProxy get copyWith => _$PackFileInputCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PackFileInput _$PackFileInputFromJson(Map<String, dynamic> json) =>
    $checkedCreate('PackFileInput', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['path', 'base64']);
      final val = PackFileInput(
        path: $checkedConvert('path', (v) => v as String),
        base64: $checkedConvert('base64', (v) => v as String),
        executable: $checkedConvert('executable', (v) => v as bool?),
      );
      return val;
    });

Map<String, dynamic> _$PackFileInputToJson(PackFileInput instance) =>
    <String, dynamic>{
      'path': instance.path,
      'base64': instance.base64,
      'executable': ?instance.executable,
    };
