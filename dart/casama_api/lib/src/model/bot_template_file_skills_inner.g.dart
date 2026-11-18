// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bot_template_file_skills_inner.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$BotTemplateFileSkillsInnerCWProxy {
  BotTemplateFileSkillsInner name(String name);

  BotTemplateFileSkillsInner description(String description);

  BotTemplateFileSkillsInner bodyMd(String bodyMd);

  BotTemplateFileSkillsInner files(
    List<BotTemplateFileSkillsInnerFilesInner>? files,
  );

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `BotTemplateFileSkillsInner(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// BotTemplateFileSkillsInner(...).copyWith(id: 12, name: "My name")
  /// ```
  BotTemplateFileSkillsInner call({
    String name,
    String description,
    String bodyMd,
    List<BotTemplateFileSkillsInnerFilesInner>? files,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfBotTemplateFileSkillsInner.copyWith(...)` or call `instanceOfBotTemplateFileSkillsInner.copyWith.fieldName(value)` for a single field.
class _$BotTemplateFileSkillsInnerCWProxyImpl
    implements _$BotTemplateFileSkillsInnerCWProxy {
  const _$BotTemplateFileSkillsInnerCWProxyImpl(this._value);

  final BotTemplateFileSkillsInner _value;

  @override
  BotTemplateFileSkillsInner name(String name) => call(name: name);

  @override
  BotTemplateFileSkillsInner description(String description) =>
      call(description: description);

  @override
  BotTemplateFileSkillsInner bodyMd(String bodyMd) => call(bodyMd: bodyMd);

  @override
  BotTemplateFileSkillsInner files(
    List<BotTemplateFileSkillsInnerFilesInner>? files,
  ) => call(files: files);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `BotTemplateFileSkillsInner(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// BotTemplateFileSkillsInner(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  BotTemplateFileSkillsInner call({
    Object? name = const $CopyWithPlaceholder(),
    Object? description = const $CopyWithPlaceholder(),
    Object? bodyMd = const $CopyWithPlaceholder(),
    Object? files = const $CopyWithPlaceholder(),
  }) {
    return BotTemplateFileSkillsInner(
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      description:
          description == const $CopyWithPlaceholder() || description == null
          ? _value.description
          // ignore: cast_nullable_to_non_nullable
          : description as String,
      bodyMd: bodyMd == const $CopyWithPlaceholder() || bodyMd == null
          ? _value.bodyMd
          // ignore: cast_nullable_to_non_nullable
          : bodyMd as String,
      files: files == const $CopyWithPlaceholder()
          ? _value.files
          // ignore: cast_nullable_to_non_nullable
          : files as List<BotTemplateFileSkillsInnerFilesInner>?,
    );
  }
}

extension $BotTemplateFileSkillsInnerCopyWith on BotTemplateFileSkillsInner {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfBotTemplateFileSkillsInner.copyWith(...)` or `instanceOfBotTemplateFileSkillsInner.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$BotTemplateFileSkillsInnerCWProxy get copyWith =>
      _$BotTemplateFileSkillsInnerCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BotTemplateFileSkillsInner _$BotTemplateFileSkillsInnerFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('BotTemplateFileSkillsInner', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['name', 'description', 'body_md']);
  final val = BotTemplateFileSkillsInner(
    name: $checkedConvert('name', (v) => v as String),
    description: $checkedConvert('description', (v) => v as String),
    bodyMd: $checkedConvert('body_md', (v) => v as String),
    files: $checkedConvert(
      'files',
      (v) => (v as List<dynamic>?)
          ?.map(
            (e) => BotTemplateFileSkillsInnerFilesInner.fromJson(
              e as Map<String, dynamic>,
            ),
          )
          .toList(),
    ),
  );
  return val;
}, fieldKeyMap: const {'bodyMd': 'body_md'});

Map<String, dynamic> _$BotTemplateFileSkillsInnerToJson(
  BotTemplateFileSkillsInner instance,
) => <String, dynamic>{
  'name': instance.name,
  'description': instance.description,
  'body_md': instance.bodyMd,
  'files': ?instance.files?.map((e) => e.toJson()).toList(),
};
