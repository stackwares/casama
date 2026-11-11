// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plugin.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PluginCWProxy {
  Plugin id(String id);

  Plugin botId(String botId);

  Plugin name(String name);

  Plugin version(String? version);

  Plugin description(String description);

  Plugin repo(String repo);

  Plugin path(String path);

  Plugin commit(String commit);

  Plugin skills(List<PluginSkillsInner> skills);

  Plugin servers(List<InstalledPluginServer> servers);

  Plugin hosts(List<String> hosts);

  Plugin secrets(List<PluginSecretInfo> secrets);

  Plugin installedAt(DateTime installedAt);

  Plugin updatedAt(DateTime updatedAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `Plugin(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// Plugin(...).copyWith(id: 12, name: "My name")
  /// ```
  Plugin call({
    String id,
    String botId,
    String name,
    String? version,
    String description,
    String repo,
    String path,
    String commit,
    List<PluginSkillsInner> skills,
    List<InstalledPluginServer> servers,
    List<String> hosts,
    List<PluginSecretInfo> secrets,
    DateTime installedAt,
    DateTime updatedAt,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfPlugin.copyWith(...)` or call `instanceOfPlugin.copyWith.fieldName(value)` for a single field.
class _$PluginCWProxyImpl implements _$PluginCWProxy {
  const _$PluginCWProxyImpl(this._value);

  final Plugin _value;

  @override
  Plugin id(String id) => call(id: id);

  @override
  Plugin botId(String botId) => call(botId: botId);

  @override
  Plugin name(String name) => call(name: name);

  @override
  Plugin version(String? version) => call(version: version);

  @override
  Plugin description(String description) => call(description: description);

  @override
  Plugin repo(String repo) => call(repo: repo);

  @override
  Plugin path(String path) => call(path: path);

  @override
  Plugin commit(String commit) => call(commit: commit);

  @override
  Plugin skills(List<PluginSkillsInner> skills) => call(skills: skills);

  @override
  Plugin servers(List<InstalledPluginServer> servers) => call(servers: servers);

  @override
  Plugin hosts(List<String> hosts) => call(hosts: hosts);

  @override
  Plugin secrets(List<PluginSecretInfo> secrets) => call(secrets: secrets);

  @override
  Plugin installedAt(DateTime installedAt) => call(installedAt: installedAt);

  @override
  Plugin updatedAt(DateTime updatedAt) => call(updatedAt: updatedAt);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `Plugin(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// Plugin(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  Plugin call({
    Object? id = const $CopyWithPlaceholder(),
    Object? botId = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? version = const $CopyWithPlaceholder(),
    Object? description = const $CopyWithPlaceholder(),
    Object? repo = const $CopyWithPlaceholder(),
    Object? path = const $CopyWithPlaceholder(),
    Object? commit = const $CopyWithPlaceholder(),
    Object? skills = const $CopyWithPlaceholder(),
    Object? servers = const $CopyWithPlaceholder(),
    Object? hosts = const $CopyWithPlaceholder(),
    Object? secrets = const $CopyWithPlaceholder(),
    Object? installedAt = const $CopyWithPlaceholder(),
    Object? updatedAt = const $CopyWithPlaceholder(),
  }) {
    return Plugin(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      botId: botId == const $CopyWithPlaceholder() || botId == null
          ? _value.botId
          // ignore: cast_nullable_to_non_nullable
          : botId as String,
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
          : skills as List<PluginSkillsInner>,
      servers: servers == const $CopyWithPlaceholder() || servers == null
          ? _value.servers
          // ignore: cast_nullable_to_non_nullable
          : servers as List<InstalledPluginServer>,
      hosts: hosts == const $CopyWithPlaceholder() || hosts == null
          ? _value.hosts
          // ignore: cast_nullable_to_non_nullable
          : hosts as List<String>,
      secrets: secrets == const $CopyWithPlaceholder() || secrets == null
          ? _value.secrets
          // ignore: cast_nullable_to_non_nullable
          : secrets as List<PluginSecretInfo>,
      installedAt:
          installedAt == const $CopyWithPlaceholder() || installedAt == null
          ? _value.installedAt
          // ignore: cast_nullable_to_non_nullable
          : installedAt as DateTime,
      updatedAt: updatedAt == const $CopyWithPlaceholder() || updatedAt == null
          ? _value.updatedAt
          // ignore: cast_nullable_to_non_nullable
          : updatedAt as DateTime,
    );
  }
}

extension $PluginCopyWith on Plugin {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfPlugin.copyWith(...)` or `instanceOfPlugin.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PluginCWProxy get copyWith => _$PluginCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Plugin _$PluginFromJson(Map<String, dynamic> json) => $checkedCreate(
  'Plugin',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'id',
        'bot_id',
        'name',
        'version',
        'description',
        'repo',
        'path',
        'commit',
        'skills',
        'servers',
        'hosts',
        'secrets',
        'installed_at',
        'updated_at',
      ],
    );
    final val = Plugin(
      id: $checkedConvert('id', (v) => v as String),
      botId: $checkedConvert('bot_id', (v) => v as String),
      name: $checkedConvert('name', (v) => v as String),
      version: $checkedConvert('version', (v) => v as String?),
      description: $checkedConvert('description', (v) => v as String),
      repo: $checkedConvert('repo', (v) => v as String),
      path: $checkedConvert('path', (v) => v as String),
      commit: $checkedConvert('commit', (v) => v as String),
      skills: $checkedConvert(
        'skills',
        (v) => (v as List<dynamic>)
            .map((e) => PluginSkillsInner.fromJson(e as Map<String, dynamic>))
            .toList(),
      ),
      servers: $checkedConvert(
        'servers',
        (v) => (v as List<dynamic>)
            .map(
              (e) => InstalledPluginServer.fromJson(e as Map<String, dynamic>),
            )
            .toList(),
      ),
      hosts: $checkedConvert(
        'hosts',
        (v) => (v as List<dynamic>).map((e) => e as String).toList(),
      ),
      secrets: $checkedConvert(
        'secrets',
        (v) => (v as List<dynamic>)
            .map((e) => PluginSecretInfo.fromJson(e as Map<String, dynamic>))
            .toList(),
      ),
      installedAt: $checkedConvert(
        'installed_at',
        (v) => DateTime.parse(v as String),
      ),
      updatedAt: $checkedConvert(
        'updated_at',
        (v) => DateTime.parse(v as String),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'botId': 'bot_id',
    'installedAt': 'installed_at',
    'updatedAt': 'updated_at',
  },
);

Map<String, dynamic> _$PluginToJson(Plugin instance) => <String, dynamic>{
  'id': instance.id,
  'bot_id': instance.botId,
  'name': instance.name,
  'version': instance.version,
  'description': instance.description,
  'repo': instance.repo,
  'path': instance.path,
  'commit': instance.commit,
  'skills': instance.skills.map((e) => e.toJson()).toList(),
  'servers': instance.servers.map((e) => e.toJson()).toList(),
  'hosts': instance.hosts,
  'secrets': instance.secrets.map((e) => e.toJson()).toList(),
  'installed_at': instance.installedAt.toIso8601String(),
  'updated_at': instance.updatedAt.toIso8601String(),
};
