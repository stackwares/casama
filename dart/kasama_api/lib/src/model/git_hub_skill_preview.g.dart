// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'git_hub_skill_preview.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$GitHubSkillPreviewCWProxy {
  GitHubSkillPreview repo(String repo);

  GitHubSkillPreview path(String path);

  GitHubSkillPreview ref(String? ref);

  GitHubSkillPreview commit(String commit);

  GitHubSkillPreview name(String name);

  GitHubSkillPreview description(String description);

  GitHubSkillPreview skillMd(String skillMd);

  GitHubSkillPreview files(List<SkillPreviewFile> files);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `GitHubSkillPreview(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// GitHubSkillPreview(...).copyWith(id: 12, name: "My name")
  /// ```
  GitHubSkillPreview call({
    String repo,
    String path,
    String? ref,
    String commit,
    String name,
    String description,
    String skillMd,
    List<SkillPreviewFile> files,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfGitHubSkillPreview.copyWith(...)` or call `instanceOfGitHubSkillPreview.copyWith.fieldName(value)` for a single field.
class _$GitHubSkillPreviewCWProxyImpl implements _$GitHubSkillPreviewCWProxy {
  const _$GitHubSkillPreviewCWProxyImpl(this._value);

  final GitHubSkillPreview _value;

  @override
  GitHubSkillPreview repo(String repo) => call(repo: repo);

  @override
  GitHubSkillPreview path(String path) => call(path: path);

  @override
  GitHubSkillPreview ref(String? ref) => call(ref: ref);

  @override
  GitHubSkillPreview commit(String commit) => call(commit: commit);

  @override
  GitHubSkillPreview name(String name) => call(name: name);

  @override
  GitHubSkillPreview description(String description) =>
      call(description: description);

  @override
  GitHubSkillPreview skillMd(String skillMd) => call(skillMd: skillMd);

  @override
  GitHubSkillPreview files(List<SkillPreviewFile> files) => call(files: files);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `GitHubSkillPreview(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// GitHubSkillPreview(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  GitHubSkillPreview call({
    Object? repo = const $CopyWithPlaceholder(),
    Object? path = const $CopyWithPlaceholder(),
    Object? ref = const $CopyWithPlaceholder(),
    Object? commit = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? description = const $CopyWithPlaceholder(),
    Object? skillMd = const $CopyWithPlaceholder(),
    Object? files = const $CopyWithPlaceholder(),
  }) {
    return GitHubSkillPreview(
      repo: repo == const $CopyWithPlaceholder() || repo == null
          ? _value.repo
          // ignore: cast_nullable_to_non_nullable
          : repo as String,
      path: path == const $CopyWithPlaceholder() || path == null
          ? _value.path
          // ignore: cast_nullable_to_non_nullable
          : path as String,
      ref: ref == const $CopyWithPlaceholder()
          ? _value.ref
          // ignore: cast_nullable_to_non_nullable
          : ref as String?,
      commit: commit == const $CopyWithPlaceholder() || commit == null
          ? _value.commit
          // ignore: cast_nullable_to_non_nullable
          : commit as String,
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      description:
          description == const $CopyWithPlaceholder() || description == null
          ? _value.description
          // ignore: cast_nullable_to_non_nullable
          : description as String,
      skillMd: skillMd == const $CopyWithPlaceholder() || skillMd == null
          ? _value.skillMd
          // ignore: cast_nullable_to_non_nullable
          : skillMd as String,
      files: files == const $CopyWithPlaceholder() || files == null
          ? _value.files
          // ignore: cast_nullable_to_non_nullable
          : files as List<SkillPreviewFile>,
    );
  }
}

extension $GitHubSkillPreviewCopyWith on GitHubSkillPreview {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfGitHubSkillPreview.copyWith(...)` or `instanceOfGitHubSkillPreview.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$GitHubSkillPreviewCWProxy get copyWith =>
      _$GitHubSkillPreviewCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GitHubSkillPreview _$GitHubSkillPreviewFromJson(Map<String, dynamic> json) =>
    $checkedCreate('GitHubSkillPreview', json, ($checkedConvert) {
      $checkKeys(
        json,
        requiredKeys: const [
          'repo',
          'path',
          'ref',
          'commit',
          'name',
          'description',
          'skill_md',
          'files',
        ],
      );
      final val = GitHubSkillPreview(
        repo: $checkedConvert('repo', (v) => v as String),
        path: $checkedConvert('path', (v) => v as String),
        ref: $checkedConvert('ref', (v) => v as String?),
        commit: $checkedConvert('commit', (v) => v as String),
        name: $checkedConvert('name', (v) => v as String),
        description: $checkedConvert('description', (v) => v as String),
        skillMd: $checkedConvert('skill_md', (v) => v as String),
        files: $checkedConvert(
          'files',
          (v) => (v as List<dynamic>)
              .map((e) => SkillPreviewFile.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    }, fieldKeyMap: const {'skillMd': 'skill_md'});

Map<String, dynamic> _$GitHubSkillPreviewToJson(GitHubSkillPreview instance) =>
    <String, dynamic>{
      'repo': instance.repo,
      'path': instance.path,
      'ref': instance.ref,
      'commit': instance.commit,
      'name': instance.name,
      'description': instance.description,
      'skill_md': instance.skillMd,
      'files': instance.files.map((e) => e.toJson()).toList(),
    };
