// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'skill_preview_file.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SkillPreviewFileCWProxy {
  SkillPreviewFile path(String path);

  SkillPreviewFile size(int size);

  SkillPreviewFile executable(bool executable);

  SkillPreviewFile text(String? text);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SkillPreviewFile(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SkillPreviewFile(...).copyWith(id: 12, name: "My name")
  /// ```
  SkillPreviewFile call({String path, int size, bool executable, String? text});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfSkillPreviewFile.copyWith(...)` or call `instanceOfSkillPreviewFile.copyWith.fieldName(value)` for a single field.
class _$SkillPreviewFileCWProxyImpl implements _$SkillPreviewFileCWProxy {
  const _$SkillPreviewFileCWProxyImpl(this._value);

  final SkillPreviewFile _value;

  @override
  SkillPreviewFile path(String path) => call(path: path);

  @override
  SkillPreviewFile size(int size) => call(size: size);

  @override
  SkillPreviewFile executable(bool executable) => call(executable: executable);

  @override
  SkillPreviewFile text(String? text) => call(text: text);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SkillPreviewFile(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SkillPreviewFile(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  SkillPreviewFile call({
    Object? path = const $CopyWithPlaceholder(),
    Object? size = const $CopyWithPlaceholder(),
    Object? executable = const $CopyWithPlaceholder(),
    Object? text = const $CopyWithPlaceholder(),
  }) {
    return SkillPreviewFile(
      path: path == const $CopyWithPlaceholder() || path == null
          ? _value.path
          // ignore: cast_nullable_to_non_nullable
          : path as String,
      size: size == const $CopyWithPlaceholder() || size == null
          ? _value.size
          // ignore: cast_nullable_to_non_nullable
          : size as int,
      executable:
          executable == const $CopyWithPlaceholder() || executable == null
          ? _value.executable
          // ignore: cast_nullable_to_non_nullable
          : executable as bool,
      text: text == const $CopyWithPlaceholder()
          ? _value.text
          // ignore: cast_nullable_to_non_nullable
          : text as String?,
    );
  }
}

extension $SkillPreviewFileCopyWith on SkillPreviewFile {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfSkillPreviewFile.copyWith(...)` or `instanceOfSkillPreviewFile.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SkillPreviewFileCWProxy get copyWith => _$SkillPreviewFileCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SkillPreviewFile _$SkillPreviewFileFromJson(Map<String, dynamic> json) =>
    $checkedCreate('SkillPreviewFile', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const ['path', 'size', 'executable', 'text'],
      );
      final val = SkillPreviewFile(
        path: $checkedConvert('path', (v) => v as String),
        size: $checkedConvert('size', (v) => (v as num).toInt()),
        executable: $checkedConvert('executable', (v) => v as bool),
        text: $checkedConvert('text', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$SkillPreviewFileToJson(SkillPreviewFile instance) =>
    <String, dynamic>{
      'path': instance.path,
      'size': instance.size,
      'executable': instance.executable,
      'text': instance.text,
    };
