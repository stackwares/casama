// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'share_pack_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SharePackRequestCWProxy {
  SharePackRequest name(String name);

  SharePackRequest summary(String summary);

  SharePackRequest description(String? description);

  SharePackRequest icon(String? icon);

  SharePackRequest botIds(List<String> botIds);

  SharePackRequest workspaceSkillIds(List<String>? workspaceSkillIds);

  SharePackRequest look(ExportPackRequestLook? look);

  SharePackRequest ignoreFindings(bool? ignoreFindings);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SharePackRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SharePackRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  SharePackRequest call({
    String name,
    String summary,
    String? description,
    String? icon,
    List<String> botIds,
    List<String>? workspaceSkillIds,
    ExportPackRequestLook? look,
    bool? ignoreFindings,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfSharePackRequest.copyWith(...)` or call `instanceOfSharePackRequest.copyWith.fieldName(value)` for a single field.
class _$SharePackRequestCWProxyImpl implements _$SharePackRequestCWProxy {
  const _$SharePackRequestCWProxyImpl(this._value);

  final SharePackRequest _value;

  @override
  SharePackRequest name(String name) => call(name: name);

  @override
  SharePackRequest summary(String summary) => call(summary: summary);

  @override
  SharePackRequest description(String? description) =>
      call(description: description);

  @override
  SharePackRequest icon(String? icon) => call(icon: icon);

  @override
  SharePackRequest botIds(List<String> botIds) => call(botIds: botIds);

  @override
  SharePackRequest workspaceSkillIds(List<String>? workspaceSkillIds) =>
      call(workspaceSkillIds: workspaceSkillIds);

  @override
  SharePackRequest look(ExportPackRequestLook? look) => call(look: look);

  @override
  SharePackRequest ignoreFindings(bool? ignoreFindings) =>
      call(ignoreFindings: ignoreFindings);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SharePackRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SharePackRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  SharePackRequest call({
    Object? name = const $CopyWithPlaceholder(),
    Object? summary = const $CopyWithPlaceholder(),
    Object? description = const $CopyWithPlaceholder(),
    Object? icon = const $CopyWithPlaceholder(),
    Object? botIds = const $CopyWithPlaceholder(),
    Object? workspaceSkillIds = const $CopyWithPlaceholder(),
    Object? look = const $CopyWithPlaceholder(),
    Object? ignoreFindings = const $CopyWithPlaceholder(),
  }) {
    return SharePackRequest(
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      summary: summary == const $CopyWithPlaceholder() || summary == null
          ? _value.summary
          // ignore: cast_nullable_to_non_nullable
          : summary as String,
      description: description == const $CopyWithPlaceholder()
          ? _value.description
          // ignore: cast_nullable_to_non_nullable
          : description as String?,
      icon: icon == const $CopyWithPlaceholder()
          ? _value.icon
          // ignore: cast_nullable_to_non_nullable
          : icon as String?,
      botIds: botIds == const $CopyWithPlaceholder() || botIds == null
          ? _value.botIds
          // ignore: cast_nullable_to_non_nullable
          : botIds as List<String>,
      workspaceSkillIds: workspaceSkillIds == const $CopyWithPlaceholder()
          ? _value.workspaceSkillIds
          // ignore: cast_nullable_to_non_nullable
          : workspaceSkillIds as List<String>?,
      look: look == const $CopyWithPlaceholder()
          ? _value.look
          // ignore: cast_nullable_to_non_nullable
          : look as ExportPackRequestLook?,
      ignoreFindings: ignoreFindings == const $CopyWithPlaceholder()
          ? _value.ignoreFindings
          // ignore: cast_nullable_to_non_nullable
          : ignoreFindings as bool?,
    );
  }
}

extension $SharePackRequestCopyWith on SharePackRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfSharePackRequest.copyWith(...)` or `instanceOfSharePackRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SharePackRequestCWProxy get copyWith => _$SharePackRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SharePackRequest _$SharePackRequestFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'SharePackRequest',
      json,
      ($checkedConvert) {
        $checkKeys(json, requiredKeys: const ['name', 'summary', 'bot_ids']);
        final val = SharePackRequest(
          name: $checkedConvert('name', (v) => v as String),
          summary: $checkedConvert('summary', (v) => v as String),
          description: $checkedConvert('description', (v) => v as String?),
          icon: $checkedConvert('icon', (v) => v as String?),
          botIds: $checkedConvert(
            'bot_ids',
            (v) => (v as List<dynamic>).map((e) => e as String).toList(),
          ),
          workspaceSkillIds: $checkedConvert(
            'workspace_skill_ids',
            (v) => (v as List<dynamic>?)?.map((e) => e as String).toList(),
          ),
          look: $checkedConvert(
            'look',
            (v) => v == null
                ? null
                : ExportPackRequestLook.fromJson(v as Map<String, dynamic>),
          ),
          ignoreFindings: $checkedConvert('ignore_findings', (v) => v as bool?),
        );
        return val;
      },
      fieldKeyMap: const {
        'botIds': 'bot_ids',
        'workspaceSkillIds': 'workspace_skill_ids',
        'ignoreFindings': 'ignore_findings',
      },
    );

Map<String, dynamic> _$SharePackRequestToJson(SharePackRequest instance) =>
    <String, dynamic>{
      'name': instance.name,
      'summary': instance.summary,
      'description': ?instance.description,
      'icon': ?instance.icon,
      'bot_ids': instance.botIds,
      'workspace_skill_ids': ?instance.workspaceSkillIds,
      'look': ?instance.look?.toJson(),
      'ignore_findings': ?instance.ignoreFindings,
    };
