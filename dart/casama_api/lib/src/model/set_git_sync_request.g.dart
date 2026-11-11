// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'set_git_sync_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SetGitSyncRequestCWProxy {
  SetGitSyncRequest repo(String repo);

  SetGitSyncRequest branch(String? branch);

  SetGitSyncRequest path(String? path);

  SetGitSyncRequest enabled(bool? enabled);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SetGitSyncRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SetGitSyncRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  SetGitSyncRequest call({
    String repo,
    String? branch,
    String? path,
    bool? enabled,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfSetGitSyncRequest.copyWith(...)` or call `instanceOfSetGitSyncRequest.copyWith.fieldName(value)` for a single field.
class _$SetGitSyncRequestCWProxyImpl implements _$SetGitSyncRequestCWProxy {
  const _$SetGitSyncRequestCWProxyImpl(this._value);

  final SetGitSyncRequest _value;

  @override
  SetGitSyncRequest repo(String repo) => call(repo: repo);

  @override
  SetGitSyncRequest branch(String? branch) => call(branch: branch);

  @override
  SetGitSyncRequest path(String? path) => call(path: path);

  @override
  SetGitSyncRequest enabled(bool? enabled) => call(enabled: enabled);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SetGitSyncRequest(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SetGitSyncRequest(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  SetGitSyncRequest call({
    Object? repo = const $CopyWithPlaceholder(),
    Object? branch = const $CopyWithPlaceholder(),
    Object? path = const $CopyWithPlaceholder(),
    Object? enabled = const $CopyWithPlaceholder(),
  }) {
    return SetGitSyncRequest(
      repo: repo == const $CopyWithPlaceholder() || repo == null
          ? _value.repo
          // ignore: cast_nullable_to_non_nullable
          : repo as String,
      branch: branch == const $CopyWithPlaceholder()
          ? _value.branch
          // ignore: cast_nullable_to_non_nullable
          : branch as String?,
      path: path == const $CopyWithPlaceholder()
          ? _value.path
          // ignore: cast_nullable_to_non_nullable
          : path as String?,
      enabled: enabled == const $CopyWithPlaceholder()
          ? _value.enabled
          // ignore: cast_nullable_to_non_nullable
          : enabled as bool?,
    );
  }
}

extension $SetGitSyncRequestCopyWith on SetGitSyncRequest {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfSetGitSyncRequest.copyWith(...)` or `instanceOfSetGitSyncRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SetGitSyncRequestCWProxy get copyWith =>
      _$SetGitSyncRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SetGitSyncRequest _$SetGitSyncRequestFromJson(Map<String, dynamic> json) =>
    $checkedCreate('SetGitSyncRequest', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['repo']);
      final val = SetGitSyncRequest(
        repo: $checkedConvert('repo', (v) => v as String),
        branch: $checkedConvert('branch', (v) => v as String?),
        path: $checkedConvert('path', (v) => v as String?),
        enabled: $checkedConvert('enabled', (v) => v as bool?),
      );
      return val;
    });

Map<String, dynamic> _$SetGitSyncRequestToJson(SetGitSyncRequest instance) =>
    <String, dynamic>{
      'repo': instance.repo,
      'branch': ?instance.branch,
      'path': ?instance.path,
      'enabled': ?instance.enabled,
    };
