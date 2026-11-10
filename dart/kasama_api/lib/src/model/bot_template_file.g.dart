// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bot_template_file.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$BotTemplateFileCWProxy {
  BotTemplateFile format(BotTemplateFileFormatEnum format);

  BotTemplateFile version(int version);

  BotTemplateFile name(String name);

  BotTemplateFile description(String? description);

  BotTemplateFile personaMd(String personaMd);

  BotTemplateFile autonomy(BotTemplateFileAutonomyEnum autonomy);

  BotTemplateFile avatar(String? avatar);

  BotTemplateFile skills(List<BotTemplateFileSkillsInner>? skills);

  BotTemplateFile routines(List<BotTemplateFileRoutinesInner>? routines);

  BotTemplateFile connections(
    List<BotTemplateFileConnectionsInner>? connections,
  );

  BotTemplateFile memories(List<BotTemplateFileMemoriesInner>? memories);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `BotTemplateFile(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// BotTemplateFile(...).copyWith(id: 12, name: "My name")
  /// ```
  BotTemplateFile call({
    BotTemplateFileFormatEnum format,
    int version,
    String name,
    String? description,
    String personaMd,
    BotTemplateFileAutonomyEnum autonomy,
    String? avatar,
    List<BotTemplateFileSkillsInner>? skills,
    List<BotTemplateFileRoutinesInner>? routines,
    List<BotTemplateFileConnectionsInner>? connections,
    List<BotTemplateFileMemoriesInner>? memories,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfBotTemplateFile.copyWith(...)` or call `instanceOfBotTemplateFile.copyWith.fieldName(value)` for a single field.
class _$BotTemplateFileCWProxyImpl implements _$BotTemplateFileCWProxy {
  const _$BotTemplateFileCWProxyImpl(this._value);

  final BotTemplateFile _value;

  @override
  BotTemplateFile format(BotTemplateFileFormatEnum format) =>
      call(format: format);

  @override
  BotTemplateFile version(int version) => call(version: version);

  @override
  BotTemplateFile name(String name) => call(name: name);

  @override
  BotTemplateFile description(String? description) =>
      call(description: description);

  @override
  BotTemplateFile personaMd(String personaMd) => call(personaMd: personaMd);

  @override
  BotTemplateFile autonomy(BotTemplateFileAutonomyEnum autonomy) =>
      call(autonomy: autonomy);

  @override
  BotTemplateFile avatar(String? avatar) => call(avatar: avatar);

  @override
  BotTemplateFile skills(List<BotTemplateFileSkillsInner>? skills) =>
      call(skills: skills);

  @override
  BotTemplateFile routines(List<BotTemplateFileRoutinesInner>? routines) =>
      call(routines: routines);

  @override
  BotTemplateFile connections(
    List<BotTemplateFileConnectionsInner>? connections,
  ) => call(connections: connections);

  @override
  BotTemplateFile memories(List<BotTemplateFileMemoriesInner>? memories) =>
      call(memories: memories);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `BotTemplateFile(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// BotTemplateFile(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  BotTemplateFile call({
    Object? format = const $CopyWithPlaceholder(),
    Object? version = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? description = const $CopyWithPlaceholder(),
    Object? personaMd = const $CopyWithPlaceholder(),
    Object? autonomy = const $CopyWithPlaceholder(),
    Object? avatar = const $CopyWithPlaceholder(),
    Object? skills = const $CopyWithPlaceholder(),
    Object? routines = const $CopyWithPlaceholder(),
    Object? connections = const $CopyWithPlaceholder(),
    Object? memories = const $CopyWithPlaceholder(),
  }) {
    return BotTemplateFile(
      format: format == const $CopyWithPlaceholder() || format == null
          ? _value.format
          // ignore: cast_nullable_to_non_nullable
          : format as BotTemplateFileFormatEnum,
      version: version == const $CopyWithPlaceholder() || version == null
          ? _value.version
          // ignore: cast_nullable_to_non_nullable
          : version as int,
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      description: description == const $CopyWithPlaceholder()
          ? _value.description
          // ignore: cast_nullable_to_non_nullable
          : description as String?,
      personaMd: personaMd == const $CopyWithPlaceholder() || personaMd == null
          ? _value.personaMd
          // ignore: cast_nullable_to_non_nullable
          : personaMd as String,
      autonomy: autonomy == const $CopyWithPlaceholder() || autonomy == null
          ? _value.autonomy
          // ignore: cast_nullable_to_non_nullable
          : autonomy as BotTemplateFileAutonomyEnum,
      avatar: avatar == const $CopyWithPlaceholder()
          ? _value.avatar
          // ignore: cast_nullable_to_non_nullable
          : avatar as String?,
      skills: skills == const $CopyWithPlaceholder()
          ? _value.skills
          // ignore: cast_nullable_to_non_nullable
          : skills as List<BotTemplateFileSkillsInner>?,
      routines: routines == const $CopyWithPlaceholder()
          ? _value.routines
          // ignore: cast_nullable_to_non_nullable
          : routines as List<BotTemplateFileRoutinesInner>?,
      connections: connections == const $CopyWithPlaceholder()
          ? _value.connections
          // ignore: cast_nullable_to_non_nullable
          : connections as List<BotTemplateFileConnectionsInner>?,
      memories: memories == const $CopyWithPlaceholder()
          ? _value.memories
          // ignore: cast_nullable_to_non_nullable
          : memories as List<BotTemplateFileMemoriesInner>?,
    );
  }
}

extension $BotTemplateFileCopyWith on BotTemplateFile {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfBotTemplateFile.copyWith(...)` or `instanceOfBotTemplateFile.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$BotTemplateFileCWProxy get copyWith => _$BotTemplateFileCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BotTemplateFile _$BotTemplateFileFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('BotTemplateFile', json, ($checkedConvert) {
  $checkKeys(
    json,
    requiredKeys: const ['format', 'version', 'name', 'persona_md', 'autonomy'],
  );
  final val = BotTemplateFile(
    format: $checkedConvert(
      'format',
      (v) => $enumDecode(_$BotTemplateFileFormatEnumEnumMap, v),
    ),
    version: $checkedConvert('version', (v) => (v as num).toInt()),
    name: $checkedConvert('name', (v) => v as String),
    description: $checkedConvert('description', (v) => v as String?),
    personaMd: $checkedConvert('persona_md', (v) => v as String),
    autonomy: $checkedConvert(
      'autonomy',
      (v) => $enumDecode(_$BotTemplateFileAutonomyEnumEnumMap, v),
    ),
    avatar: $checkedConvert('avatar', (v) => v as String?),
    skills: $checkedConvert(
      'skills',
      (v) => (v as List<dynamic>?)
          ?.map(
            (e) =>
                BotTemplateFileSkillsInner.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
    ),
    routines: $checkedConvert(
      'routines',
      (v) => (v as List<dynamic>?)
          ?.map(
            (e) => BotTemplateFileRoutinesInner.fromJson(
              e as Map<String, dynamic>,
            ),
          )
          .toList(),
    ),
    connections: $checkedConvert(
      'connections',
      (v) => (v as List<dynamic>?)
          ?.map(
            (e) => BotTemplateFileConnectionsInner.fromJson(
              e as Map<String, dynamic>,
            ),
          )
          .toList(),
    ),
    memories: $checkedConvert(
      'memories',
      (v) => (v as List<dynamic>?)
          ?.map(
            (e) => BotTemplateFileMemoriesInner.fromJson(
              e as Map<String, dynamic>,
            ),
          )
          .toList(),
    ),
  );
  return val;
}, fieldKeyMap: const {'personaMd': 'persona_md'});

Map<String, dynamic> _$BotTemplateFileToJson(BotTemplateFile instance) =>
    <String, dynamic>{
      'format': _$BotTemplateFileFormatEnumEnumMap[instance.format]!,
      'version': instance.version,
      'name': instance.name,
      'description': ?instance.description,
      'persona_md': instance.personaMd,
      'autonomy': _$BotTemplateFileAutonomyEnumEnumMap[instance.autonomy]!,
      'avatar': ?instance.avatar,
      'skills': ?instance.skills?.map((e) => e.toJson()).toList(),
      'routines': ?instance.routines?.map((e) => e.toJson()).toList(),
      'connections': ?instance.connections?.map((e) => e.toJson()).toList(),
      'memories': ?instance.memories?.map((e) => e.toJson()).toList(),
    };

const _$BotTemplateFileFormatEnumEnumMap = {
  BotTemplateFileFormatEnum.kasamaPeriodBot: 'kasama.bot',
};

const _$BotTemplateFileAutonomyEnumEnumMap = {
  BotTemplateFileAutonomyEnum.askAlways: 'ask_always',
  BotTemplateFileAutonomyEnum.askRisky: 'ask_risky',
  BotTemplateFileAutonomyEnum.autonomous: 'autonomous',
};
