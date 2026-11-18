// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bot_template_file_skills_inner_files_inner.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$BotTemplateFileSkillsInnerFilesInnerCWProxy {
  BotTemplateFileSkillsInnerFilesInner path(String path);

  BotTemplateFileSkillsInnerFilesInner contentBase64(String contentBase64);

  BotTemplateFileSkillsInnerFilesInner executable(bool? executable);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `BotTemplateFileSkillsInnerFilesInner(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// BotTemplateFileSkillsInnerFilesInner(...).copyWith(id: 12, name: "My name")
  /// ```
  BotTemplateFileSkillsInnerFilesInner call({
    String path,
    String contentBase64,
    bool? executable,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfBotTemplateFileSkillsInnerFilesInner.copyWith(...)` or call `instanceOfBotTemplateFileSkillsInnerFilesInner.copyWith.fieldName(value)` for a single field.
class _$BotTemplateFileSkillsInnerFilesInnerCWProxyImpl
    implements _$BotTemplateFileSkillsInnerFilesInnerCWProxy {
  const _$BotTemplateFileSkillsInnerFilesInnerCWProxyImpl(this._value);

  final BotTemplateFileSkillsInnerFilesInner _value;

  @override
  BotTemplateFileSkillsInnerFilesInner path(String path) => call(path: path);

  @override
  BotTemplateFileSkillsInnerFilesInner contentBase64(String contentBase64) =>
      call(contentBase64: contentBase64);

  @override
  BotTemplateFileSkillsInnerFilesInner executable(bool? executable) =>
      call(executable: executable);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `BotTemplateFileSkillsInnerFilesInner(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// BotTemplateFileSkillsInnerFilesInner(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  BotTemplateFileSkillsInnerFilesInner call({
    Object? path = const $CopyWithPlaceholder(),
    Object? contentBase64 = const $CopyWithPlaceholder(),
    Object? executable = const $CopyWithPlaceholder(),
  }) {
    return BotTemplateFileSkillsInnerFilesInner(
      path: path == const $CopyWithPlaceholder() || path == null
          ? _value.path
          // ignore: cast_nullable_to_non_nullable
          : path as String,
      contentBase64:
          contentBase64 == const $CopyWithPlaceholder() || contentBase64 == null
          ? _value.contentBase64
          // ignore: cast_nullable_to_non_nullable
          : contentBase64 as String,
      executable: executable == const $CopyWithPlaceholder()
          ? _value.executable
          // ignore: cast_nullable_to_non_nullable
          : executable as bool?,
    );
  }
}

extension $BotTemplateFileSkillsInnerFilesInnerCopyWith
    on BotTemplateFileSkillsInnerFilesInner {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfBotTemplateFileSkillsInnerFilesInner.copyWith(...)` or `instanceOfBotTemplateFileSkillsInnerFilesInner.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$BotTemplateFileSkillsInnerFilesInnerCWProxy get copyWith =>
      _$BotTemplateFileSkillsInnerFilesInnerCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BotTemplateFileSkillsInnerFilesInner
_$BotTemplateFileSkillsInnerFilesInnerFromJson(Map<String, dynamic> json) =>
    $checkedCreate('BotTemplateFileSkillsInnerFilesInner', json, (
      $checkedConvert,
    ) {
      $checkKeys(json, requiredKeys: const ['path', 'content_base64']);
      final val = BotTemplateFileSkillsInnerFilesInner(
        path: $checkedConvert('path', (v) => v as String),
        contentBase64: $checkedConvert('content_base64', (v) => v as String),
        executable: $checkedConvert('executable', (v) => v as bool?),
      );
      return val;
    }, fieldKeyMap: const {'contentBase64': 'content_base64'});

Map<String, dynamic> _$BotTemplateFileSkillsInnerFilesInnerToJson(
  BotTemplateFileSkillsInnerFilesInner instance,
) => <String, dynamic>{
  'path': instance.path,
  'content_base64': instance.contentBase64,
  'executable': ?instance.executable,
};
