// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pack_export_file.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PackExportFileCWProxy {
  PackExportFile path(String path);

  PackExportFile text(String? text);

  PackExportFile base64(String? base64);

  PackExportFile executable(bool executable);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PackExportFile(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PackExportFile(...).copyWith(id: 12, name: "My name")
  /// ```
  PackExportFile call({
    String path,
    String? text,
    String? base64,
    bool executable,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfPackExportFile.copyWith(...)` or call `instanceOfPackExportFile.copyWith.fieldName(value)` for a single field.
class _$PackExportFileCWProxyImpl implements _$PackExportFileCWProxy {
  const _$PackExportFileCWProxyImpl(this._value);

  final PackExportFile _value;

  @override
  PackExportFile path(String path) => call(path: path);

  @override
  PackExportFile text(String? text) => call(text: text);

  @override
  PackExportFile base64(String? base64) => call(base64: base64);

  @override
  PackExportFile executable(bool executable) => call(executable: executable);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PackExportFile(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PackExportFile(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  PackExportFile call({
    Object? path = const $CopyWithPlaceholder(),
    Object? text = const $CopyWithPlaceholder(),
    Object? base64 = const $CopyWithPlaceholder(),
    Object? executable = const $CopyWithPlaceholder(),
  }) {
    return PackExportFile(
      path: path == const $CopyWithPlaceholder() || path == null
          ? _value.path
          // ignore: cast_nullable_to_non_nullable
          : path as String,
      text: text == const $CopyWithPlaceholder()
          ? _value.text
          // ignore: cast_nullable_to_non_nullable
          : text as String?,
      base64: base64 == const $CopyWithPlaceholder()
          ? _value.base64
          // ignore: cast_nullable_to_non_nullable
          : base64 as String?,
      executable:
          executable == const $CopyWithPlaceholder() || executable == null
          ? _value.executable
          // ignore: cast_nullable_to_non_nullable
          : executable as bool,
    );
  }
}

extension $PackExportFileCopyWith on PackExportFile {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfPackExportFile.copyWith(...)` or `instanceOfPackExportFile.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PackExportFileCWProxy get copyWith => _$PackExportFileCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PackExportFile _$PackExportFileFromJson(Map<String, dynamic> json) =>
    $checkedCreate('PackExportFile', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const ['path', 'text', 'base64', 'executable'],
      );
      final val = PackExportFile(
        path: $checkedConvert('path', (v) => v as String),
        text: $checkedConvert('text', (v) => v as String?),
        base64: $checkedConvert('base64', (v) => v as String?),
        executable: $checkedConvert('executable', (v) => v as bool),
      );
      return val;
    });

Map<String, dynamic> _$PackExportFileToJson(PackExportFile instance) =>
    <String, dynamic>{
      'path': instance.path,
      'text': instance.text,
      'base64': instance.base64,
      'executable': instance.executable,
    };
