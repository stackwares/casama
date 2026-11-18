// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'export_pack_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$ExportPackRequestCWProxy {
  ExportPackRequest name(String name);

  ExportPackRequest summary(String summary);

  ExportPackRequest description(String? description);

  ExportPackRequest icon(String? icon);

  ExportPackRequest botIds(List<String> botIds);

  ExportPackRequest workspaceSkillIds(List<String>? workspaceSkillIds);

  ExportPackRequest look(ExportPackRequestLook? look);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ExportPackRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ExportPackRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  ExportPackRequest call({
    String name,
    String summary,
    String? description,
    String? icon,
    List<String> botIds,
    List<String>? workspaceSkillIds,
    ExportPackRequestLook? look,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfExportPackRequest.copyWith(...)` or call `instanceOfExportPackRequest.copyWith.fieldName(value)` for a single field.
class _$ExportPackRequestCWProxyImpl implements _$ExportPackRequestCWProxy {
  const _$ExportPackRequestCWProxyImpl(this._value);

  final ExportPackRequest _value;

  @override
  ExportPackRequest name(String name) => call(name: name);

  @override
  ExportPackRequest summary(String summary) => call(summary: summary);

  @override
  ExportPackRequest description(String? description) =>
      call(description: description);

  @override
  ExportPackRequest icon(String? icon) => call(icon: icon);

  @override
  ExportPackRequest botIds(List<String> botIds) => call(botIds: botIds);

  @override
  ExportPackRequest workspaceSkillIds(List<String>? workspaceSkillIds) =>
      call(workspaceSkillIds: workspaceSkillIds);

  @override
  ExportPackRequest look(ExportPackRequestLook? look) => call(look: look);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `ExportPackRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// ExportPackRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  ExportPackRequest call({
    Object? name = const $CopyWithPlaceholder(),
    Object? summary = const $CopyWithPlaceholder(),
    Object? description = const $CopyWithPlaceholder(),
    Object? icon = const $CopyWithPlaceholder(),
    Object? botIds = const $CopyWithPlaceholder(),
    Object? workspaceSkillIds = const $CopyWithPlaceholder(),
    Object? look = const $CopyWithPlaceholder(),
  }) {
    return ExportPackRequest(
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
    );
  }
}

extension $ExportPackRequestCopyWith on ExportPackRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfExportPackRequest.copyWith(...)` or `instanceOfExportPackRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$ExportPackRequestCWProxy get copyWith =>
      _$ExportPackRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ExportPackRequest _$ExportPackRequestFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'ExportPackRequest',
      json,
      ($checkedConvert) {
        $checkKeys(json, requiredKeys: const ['name', 'summary', 'bot_ids']);
        final val = ExportPackRequest(
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
        );
        return val;
      },
      fieldKeyMap: const {
        'botIds': 'bot_ids',
        'workspaceSkillIds': 'workspace_skill_ids',
      },
    );

Map<String, dynamic> _$ExportPackRequestToJson(ExportPackRequest instance) =>
    <String, dynamic>{
      'name': instance.name,
      'summary': instance.summary,
      'description': ?instance.description,
      'icon': ?instance.icon,
      'bot_ids': instance.botIds,
      'workspace_skill_ids': ?instance.workspaceSkillIds,
      'look': ?instance.look?.toJson(),
    };
