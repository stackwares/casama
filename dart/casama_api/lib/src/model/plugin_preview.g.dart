// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plugin_preview.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PluginPreviewCWProxy {
  PluginPreview name(String name);

  PluginPreview version(String? version);

  PluginPreview description(String description);

  PluginPreview repo(String repo);

  PluginPreview path(String path);

  PluginPreview commit(String commit);

  PluginPreview skills(List<PluginPreviewSkillsInner> skills);

  PluginPreview servers(List<PluginServerInfo> servers);

  PluginPreview secrets(List<PluginSecretInfo> secrets);

  PluginPreview hosts(List<String> hosts);

  PluginPreview warnings(List<String> warnings);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PluginPreview(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PluginPreview(...).copyWith(id: 12, name: "My name")
  /// ```
  PluginPreview call({
    String name,
    String? version,
    String description,
    String repo,
    String path,
    String commit,
    List<PluginPreviewSkillsInner> skills,
    List<PluginServerInfo> servers,
    List<PluginSecretInfo> secrets,
    List<String> hosts,
    List<String> warnings,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfPluginPreview.copyWith(...)` or call `instanceOfPluginPreview.copyWith.fieldName(value)` for a single field.
class _$PluginPreviewCWProxyImpl implements _$PluginPreviewCWProxy {
  const _$PluginPreviewCWProxyImpl(this._value);

  final PluginPreview _value;

  @override
  PluginPreview name(String name) => call(name: name);

  @override
  PluginPreview version(String? version) => call(version: version);

  @override
  PluginPreview description(String description) =>
      call(description: description);

  @override
  PluginPreview repo(String repo) => call(repo: repo);

  @override
  PluginPreview path(String path) => call(path: path);

  @override
  PluginPreview commit(String commit) => call(commit: commit);

  @override
  PluginPreview skills(List<PluginPreviewSkillsInner> skills) =>
      call(skills: skills);

  @override
  PluginPreview servers(List<PluginServerInfo> servers) =>
      call(servers: servers);

  @override
  PluginPreview secrets(List<PluginSecretInfo> secrets) =>
      call(secrets: secrets);

  @override
  PluginPreview hosts(List<String> hosts) => call(hosts: hosts);

  @override
  PluginPreview warnings(List<String> warnings) => call(warnings: warnings);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `PluginPreview(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// PluginPreview(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  PluginPreview call({
    Object? name = const $CopyWithPlaceholder(),
    Object? version = const $CopyWithPlaceholder(),
    Object? description = const $CopyWithPlaceholder(),
    Object? repo = const $CopyWithPlaceholder(),
    Object? path = const $CopyWithPlaceholder(),
    Object? commit = const $CopyWithPlaceholder(),
    Object? skills = const $CopyWithPlaceholder(),
    Object? servers = const $CopyWithPlaceholder(),
    Object? secrets = const $CopyWithPlaceholder(),
    Object? hosts = const $CopyWithPlaceholder(),
    Object? warnings = const $CopyWithPlaceholder(),
  }) {
    return PluginPreview(
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      version: version == const $CopyWithPlaceholder()
          ? _value.version
          // ignore: cast_nullable_to_non_nullable
          : version as String?,
      description:
          description == const $CopyWithPlaceholder() || description == null
          ? _value.description
          // ignore: cast_nullable_to_non_nullable
          : description as String,
      repo: repo == const $CopyWithPlaceholder() || repo == null
          ? _value.repo
          // ignore: cast_nullable_to_non_nullable
          : repo as String,
      path: path == const $CopyWithPlaceholder() || path == null
          ? _value.path
          // ignore: cast_nullable_to_non_nullable
          : path as String,
      commit: commit == const $CopyWithPlaceholder() || commit == null
          ? _value.commit
          // ignore: cast_nullable_to_non_nullable
          : commit as String,
      skills: skills == const $CopyWithPlaceholder() || skills == null
          ? _value.skills
          // ignore: cast_nullable_to_non_nullable
          : skills as List<PluginPreviewSkillsInner>,
      servers: servers == const $CopyWithPlaceholder() || servers == null
          ? _value.servers
          // ignore: cast_nullable_to_non_nullable
          : servers as List<PluginServerInfo>,
      secrets: secrets == const $CopyWithPlaceholder() || secrets == null
          ? _value.secrets
          // ignore: cast_nullable_to_non_nullable
          : secrets as List<PluginSecretInfo>,
      hosts: hosts == const $CopyWithPlaceholder() || hosts == null
          ? _value.hosts
          // ignore: cast_nullable_to_non_nullable
          : hosts as List<String>,
      warnings: warnings == const $CopyWithPlaceholder() || warnings == null
          ? _value.warnings
          // ignore: cast_nullable_to_non_nullable
          : warnings as List<String>,
    );
  }
}

extension $PluginPreviewCopyWith on PluginPreview {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfPluginPreview.copyWith(...)` or `instanceOfPluginPreview.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PluginPreviewCWProxy get copyWith => _$PluginPreviewCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PluginPreview _$PluginPreviewFromJson(Map<String, dynamic> json) =>
    $checkedCreate('PluginPreview', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const [
          'name',
          'version',
          'description',
          'repo',
          'path',
          'commit',
          'skills',
          'servers',
          'secrets',
          'hosts',
          'warnings',
        ],
      );
      final val = PluginPreview(
        name: $checkedConvert('name', (v) => v as String),
        version: $checkedConvert('version', (v) => v as String?),
        description: $checkedConvert('description', (v) => v as String),
        repo: $checkedConvert('repo', (v) => v as String),
        path: $checkedConvert('path', (v) => v as String),
        commit: $checkedConvert('commit', (v) => v as String),
        skills: $checkedConvert(
          'skills',
          (v) => (v as List<dynamic>)
              .map(
                (e) => PluginPreviewSkillsInner.fromJson(
                  e as Map<String, dynamic>,
                ),
              )
              .toList(),
        ),
        servers: $checkedConvert(
          'servers',
          (v) => (v as List<dynamic>)
              .map((e) => PluginServerInfo.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
        secrets: $checkedConvert(
          'secrets',
          (v) => (v as List<dynamic>)
              .map((e) => PluginSecretInfo.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
        hosts: $checkedConvert(
          'hosts',
          (v) => (v as List<dynamic>).map((e) => e as String).toList(),
        ),
        warnings: $checkedConvert(
          'warnings',
          (v) => (v as List<dynamic>).map((e) => e as String).toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$PluginPreviewToJson(PluginPreview instance) =>
    <String, dynamic>{
      'name': instance.name,
      'version': instance.version,
      'description': instance.description,
      'repo': instance.repo,
      'path': instance.path,
      'commit': instance.commit,
      'skills': instance.skills.map((e) => e.toJson()).toList(),
      'servers': instance.servers.map((e) => e.toJson()).toList(),
      'secrets': instance.secrets.map((e) => e.toJson()).toList(),
      'hosts': instance.hosts,
      'warnings': instance.warnings,
    };
