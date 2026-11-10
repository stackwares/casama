// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'install_git_hub_skill_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$InstallGitHubSkillRequestCWProxy {
  InstallGitHubSkillRequest orgId(String orgId);

  InstallGitHubSkillRequest botId(String? botId);

  InstallGitHubSkillRequest url(String url);

  InstallGitHubSkillRequest commit(String commit);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `InstallGitHubSkillRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// InstallGitHubSkillRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  InstallGitHubSkillRequest call({
    String orgId,
    String? botId,
    String url,
    String commit,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfInstallGitHubSkillRequest.copyWith(...)` or call `instanceOfInstallGitHubSkillRequest.copyWith.fieldName(value)` for a single field.
class _$InstallGitHubSkillRequestCWProxyImpl
    implements _$InstallGitHubSkillRequestCWProxy {
  const _$InstallGitHubSkillRequestCWProxyImpl(this._value);

  final InstallGitHubSkillRequest _value;

  @override
  InstallGitHubSkillRequest orgId(String orgId) => call(orgId: orgId);

  @override
  InstallGitHubSkillRequest botId(String? botId) => call(botId: botId);

  @override
  InstallGitHubSkillRequest url(String url) => call(url: url);

  @override
  InstallGitHubSkillRequest commit(String commit) => call(commit: commit);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `InstallGitHubSkillRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// InstallGitHubSkillRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  InstallGitHubSkillRequest call({
    Object? orgId = const $CopyWithPlaceholder(),
    Object? botId = const $CopyWithPlaceholder(),
    Object? url = const $CopyWithPlaceholder(),
    Object? commit = const $CopyWithPlaceholder(),
  }) {
    return InstallGitHubSkillRequest(
      orgId: orgId == const $CopyWithPlaceholder() || orgId == null
          ? _value.orgId
          // ignore: cast_nullable_to_non_nullable
          : orgId as String,
      botId: botId == const $CopyWithPlaceholder()
          ? _value.botId
          // ignore: cast_nullable_to_non_nullable
          : botId as String?,
      url: url == const $CopyWithPlaceholder() || url == null
          ? _value.url
          // ignore: cast_nullable_to_non_nullable
          : url as String,
      commit: commit == const $CopyWithPlaceholder() || commit == null
          ? _value.commit
          // ignore: cast_nullable_to_non_nullable
          : commit as String,
    );
  }
}

extension $InstallGitHubSkillRequestCopyWith on InstallGitHubSkillRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfInstallGitHubSkillRequest.copyWith(...)` or `instanceOfInstallGitHubSkillRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$InstallGitHubSkillRequestCWProxy get copyWith =>
      _$InstallGitHubSkillRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InstallGitHubSkillRequest _$InstallGitHubSkillRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('InstallGitHubSkillRequest', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['org_id', 'url', 'commit']);
  final val = InstallGitHubSkillRequest(
    orgId: $checkedConvert('org_id', (v) => v as String),
    botId: $checkedConvert('bot_id', (v) => v as String?),
    url: $checkedConvert('url', (v) => v as String),
    commit: $checkedConvert('commit', (v) => v as String),
  );
  return val;
}, fieldKeyMap: const {'orgId': 'org_id', 'botId': 'bot_id'});

Map<String, dynamic> _$InstallGitHubSkillRequestToJson(
  InstallGitHubSkillRequest instance,
) => <String, dynamic>{
  'org_id': instance.orgId,
  'bot_id': ?instance.botId,
  'url': instance.url,
  'commit': instance.commit,
};
