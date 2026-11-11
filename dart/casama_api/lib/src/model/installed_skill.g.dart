// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'installed_skill.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$InstalledSkillCWProxy {
  InstalledSkill id(String id);

  InstalledSkill orgId(String orgId);

  InstalledSkill botId(String? botId);

  InstalledSkill name(String name);

  InstalledSkill description(String description);

  InstalledSkill source_(InstalledSkillSource_Enum source_);

  InstalledSkill sourceRef(Map<String, Object?> sourceRef);

  InstalledSkill category(String? category);

  InstalledSkill fileCount(int fileCount);

  InstalledSkill updatedAt(DateTime updatedAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `InstalledSkill(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// InstalledSkill(...).copyWith(id: 12, name: "My name")
  /// ```
  InstalledSkill call({
    String id,
    String orgId,
    String? botId,
    String name,
    String description,
    InstalledSkillSource_Enum source_,
    Map<String, Object?> sourceRef,
    String? category,
    int fileCount,
    DateTime updatedAt,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfInstalledSkill.copyWith(...)` or call `instanceOfInstalledSkill.copyWith.fieldName(value)` for a single field.
class _$InstalledSkillCWProxyImpl implements _$InstalledSkillCWProxy {
  const _$InstalledSkillCWProxyImpl(this._value);

  final InstalledSkill _value;

  @override
  InstalledSkill id(String id) => call(id: id);

  @override
  InstalledSkill orgId(String orgId) => call(orgId: orgId);

  @override
  InstalledSkill botId(String? botId) => call(botId: botId);

  @override
  InstalledSkill name(String name) => call(name: name);

  @override
  InstalledSkill description(String description) =>
      call(description: description);

  @override
  InstalledSkill source_(InstalledSkillSource_Enum source_) =>
      call(source_: source_);

  @override
  InstalledSkill sourceRef(Map<String, Object?> sourceRef) =>
      call(sourceRef: sourceRef);

  @override
  InstalledSkill category(String? category) => call(category: category);

  @override
  InstalledSkill fileCount(int fileCount) => call(fileCount: fileCount);

  @override
  InstalledSkill updatedAt(DateTime updatedAt) => call(updatedAt: updatedAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `InstalledSkill(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// InstalledSkill(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  InstalledSkill call({
    Object? id = const $CopyWithPlaceholder(),
    Object? orgId = const $CopyWithPlaceholder(),
    Object? botId = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? description = const $CopyWithPlaceholder(),
    Object? source_ = const $CopyWithPlaceholder(),
    Object? sourceRef = const $CopyWithPlaceholder(),
    Object? category = const $CopyWithPlaceholder(),
    Object? fileCount = const $CopyWithPlaceholder(),
    Object? updatedAt = const $CopyWithPlaceholder(),
  }) {
    return InstalledSkill(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      orgId: orgId == const $CopyWithPlaceholder() || orgId == null
          ? _value.orgId
          // ignore: cast_nullable_to_non_nullable
          : orgId as String,
      botId: botId == const $CopyWithPlaceholder()
          ? _value.botId
          // ignore: cast_nullable_to_non_nullable
          : botId as String?,
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      description:
          description == const $CopyWithPlaceholder() || description == null
          ? _value.description
          // ignore: cast_nullable_to_non_nullable
          : description as String,
      source_: source_ == const $CopyWithPlaceholder() || source_ == null
          ? _value.source_
          // ignore: cast_nullable_to_non_nullable
          : source_ as InstalledSkillSource_Enum,
      sourceRef: sourceRef == const $CopyWithPlaceholder() || sourceRef == null
          ? _value.sourceRef
          // ignore: cast_nullable_to_non_nullable
          : sourceRef as Map<String, Object?>,
      category: category == const $CopyWithPlaceholder()
          ? _value.category
          // ignore: cast_nullable_to_non_nullable
          : category as String?,
      fileCount: fileCount == const $CopyWithPlaceholder() || fileCount == null
          ? _value.fileCount
          // ignore: cast_nullable_to_non_nullable
          : fileCount as int,
      updatedAt: updatedAt == const $CopyWithPlaceholder() || updatedAt == null
          ? _value.updatedAt
          // ignore: cast_nullable_to_non_nullable
          : updatedAt as DateTime,
    );
  }
}

extension $InstalledSkillCopyWith on InstalledSkill {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfInstalledSkill.copyWith(...)` or `instanceOfInstalledSkill.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$InstalledSkillCWProxy get copyWith => _$InstalledSkillCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InstalledSkill _$InstalledSkillFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'InstalledSkill',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'id',
            'org_id',
            'bot_id',
            'name',
            'description',
            'source',
            'source_ref',
            'category',
            'file_count',
            'updated_at',
          ],
        );
        final val = InstalledSkill(
          id: $checkedConvert('id', (v) => v as String),
          orgId: $checkedConvert('org_id', (v) => v as String),
          botId: $checkedConvert('bot_id', (v) => v as String?),
          name: $checkedConvert('name', (v) => v as String),
          description: $checkedConvert('description', (v) => v as String),
          source_: $checkedConvert(
            'source',
            (v) => $enumDecode(_$InstalledSkillSource_EnumEnumMap, v),
          ),
          sourceRef: $checkedConvert(
            'source_ref',
            (v) => v as Map<String, dynamic>,
          ),
          category: $checkedConvert('category', (v) => v as String?),
          fileCount: $checkedConvert('file_count', (v) => (v as num).toInt()),
          updatedAt: $checkedConvert(
            'updated_at',
            (v) => DateTime.parse(v as String),
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'orgId': 'org_id',
        'botId': 'bot_id',
        'source_': 'source',
        'sourceRef': 'source_ref',
        'fileCount': 'file_count',
        'updatedAt': 'updated_at',
      },
    );

Map<String, dynamic> _$InstalledSkillToJson(InstalledSkill instance) =>
    <String, dynamic>{
      'id': instance.id,
      'org_id': instance.orgId,
      'bot_id': instance.botId,
      'name': instance.name,
      'description': instance.description,
      'source': _$InstalledSkillSource_EnumEnumMap[instance.source_]!,
      'source_ref': instance.sourceRef,
      'category': instance.category,
      'file_count': instance.fileCount,
      'updated_at': instance.updatedAt.toIso8601String(),
    };

const _$InstalledSkillSource_EnumEnumMap = {
  InstalledSkillSource_Enum.manual: 'manual',
  InstalledSkillSource_Enum.catalog: 'catalog',
  InstalledSkillSource_Enum.github: 'github',
  InstalledSkillSource_Enum.bot: 'bot',
};
