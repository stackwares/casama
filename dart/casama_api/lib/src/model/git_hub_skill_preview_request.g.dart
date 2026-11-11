// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'git_hub_skill_preview_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$GitHubSkillPreviewRequestCWProxy {
  GitHubSkillPreviewRequest orgId(String orgId);

  GitHubSkillPreviewRequest url(String url);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `GitHubSkillPreviewRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// GitHubSkillPreviewRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  GitHubSkillPreviewRequest call({String orgId, String url});
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfGitHubSkillPreviewRequest.copyWith(...)` or call `instanceOfGitHubSkillPreviewRequest.copyWith.fieldName(value)` for a single field.
class _$GitHubSkillPreviewRequestCWProxyImpl
    implements _$GitHubSkillPreviewRequestCWProxy {
  const _$GitHubSkillPreviewRequestCWProxyImpl(this._value);

  final GitHubSkillPreviewRequest _value;

  @override
  GitHubSkillPreviewRequest orgId(String orgId) => call(orgId: orgId);

  @override
  GitHubSkillPreviewRequest url(String url) => call(url: url);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `GitHubSkillPreviewRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// GitHubSkillPreviewRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  GitHubSkillPreviewRequest call({
    Object? orgId = const $CopyWithPlaceholder(),
    Object? url = const $CopyWithPlaceholder(),
  }) {
    return GitHubSkillPreviewRequest(
      orgId: orgId == const $CopyWithPlaceholder() || orgId == null
          ? _value.orgId
          // ignore: cast_nullable_to_non_nullable
          : orgId as String,
      url: url == const $CopyWithPlaceholder() || url == null
          ? _value.url
          // ignore: cast_nullable_to_non_nullable
          : url as String,
    );
  }
}

extension $GitHubSkillPreviewRequestCopyWith on GitHubSkillPreviewRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfGitHubSkillPreviewRequest.copyWith(...)` or `instanceOfGitHubSkillPreviewRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$GitHubSkillPreviewRequestCWProxy get copyWith =>
      _$GitHubSkillPreviewRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GitHubSkillPreviewRequest _$GitHubSkillPreviewRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('GitHubSkillPreviewRequest', json, ($checkedConvert) {
  $checkKeys(json, requiredKeys: const ['org_id', 'url']);
  final val = GitHubSkillPreviewRequest(
    orgId: $checkedConvert('org_id', (v) => v as String),
    url: $checkedConvert('url', (v) => v as String),
  );
  return val;
}, fieldKeyMap: const {'orgId': 'org_id'});

Map<String, dynamic> _$GitHubSkillPreviewRequestToJson(
  GitHubSkillPreviewRequest instance,
) => <String, dynamic>{'org_id': instance.orgId, 'url': instance.url};
