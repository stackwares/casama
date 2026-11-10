// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'git_sync_status.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$GitSyncStatusCWProxy {
  GitSyncStatus configured(bool configured);

  GitSyncStatus repo(String? repo);

  GitSyncStatus branch(String? branch);

  GitSyncStatus path(String? path);

  GitSyncStatus enabled(bool enabled);

  GitSyncStatus hasToken(bool hasToken);

  GitSyncStatus webhookUrl(String? webhookUrl);

  GitSyncStatus webhookSecret(String? webhookSecret);

  GitSyncStatus lastSyncedAt(DateTime? lastSyncedAt);

  GitSyncStatus lastCommit(String? lastCommit);

  GitSyncStatus lastError(String? lastError);

  GitSyncStatus openPrUrl(String? openPrUrl);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `GitSyncStatus(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// GitSyncStatus(...).copyWith(id: 12, name: "My name")
  /// ```
  GitSyncStatus call({
    bool configured,
    String? repo,
    String? branch,
    String? path,
    bool enabled,
    bool hasToken,
    String? webhookUrl,
    String? webhookSecret,
    DateTime? lastSyncedAt,
    String? lastCommit,
    String? lastError,
    String? openPrUrl,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfGitSyncStatus.copyWith(...)` or call `instanceOfGitSyncStatus.copyWith.fieldName(value)` for a single field.
class _$GitSyncStatusCWProxyImpl implements _$GitSyncStatusCWProxy {
  const _$GitSyncStatusCWProxyImpl(this._value);

  final GitSyncStatus _value;

  @override
  GitSyncStatus configured(bool configured) => call(configured: configured);

  @override
  GitSyncStatus repo(String? repo) => call(repo: repo);

  @override
  GitSyncStatus branch(String? branch) => call(branch: branch);

  @override
  GitSyncStatus path(String? path) => call(path: path);

  @override
  GitSyncStatus enabled(bool enabled) => call(enabled: enabled);

  @override
  GitSyncStatus hasToken(bool hasToken) => call(hasToken: hasToken);

  @override
  GitSyncStatus webhookUrl(String? webhookUrl) => call(webhookUrl: webhookUrl);

  @override
  GitSyncStatus webhookSecret(String? webhookSecret) =>
      call(webhookSecret: webhookSecret);

  @override
  GitSyncStatus lastSyncedAt(DateTime? lastSyncedAt) =>
      call(lastSyncedAt: lastSyncedAt);

  @override
  GitSyncStatus lastCommit(String? lastCommit) => call(lastCommit: lastCommit);

  @override
  GitSyncStatus lastError(String? lastError) => call(lastError: lastError);

  @override
  GitSyncStatus openPrUrl(String? openPrUrl) => call(openPrUrl: openPrUrl);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `GitSyncStatus(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// GitSyncStatus(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  GitSyncStatus call({
    Object? configured = const $CopyWithPlaceholder(),
    Object? repo = const $CopyWithPlaceholder(),
    Object? branch = const $CopyWithPlaceholder(),
    Object? path = const $CopyWithPlaceholder(),
    Object? enabled = const $CopyWithPlaceholder(),
    Object? hasToken = const $CopyWithPlaceholder(),
    Object? webhookUrl = const $CopyWithPlaceholder(),
    Object? webhookSecret = const $CopyWithPlaceholder(),
    Object? lastSyncedAt = const $CopyWithPlaceholder(),
    Object? lastCommit = const $CopyWithPlaceholder(),
    Object? lastError = const $CopyWithPlaceholder(),
    Object? openPrUrl = const $CopyWithPlaceholder(),
  }) {
    return GitSyncStatus(
      configured:
          configured == const $CopyWithPlaceholder() || configured == null
          ? _value.configured
          // ignore: cast_nullable_to_non_nullable
          : configured as bool,
      repo: repo == const $CopyWithPlaceholder()
          ? _value.repo
          // ignore: cast_nullable_to_non_nullable
          : repo as String?,
      branch: branch == const $CopyWithPlaceholder()
          ? _value.branch
          // ignore: cast_nullable_to_non_nullable
          : branch as String?,
      path: path == const $CopyWithPlaceholder()
          ? _value.path
          // ignore: cast_nullable_to_non_nullable
          : path as String?,
      enabled: enabled == const $CopyWithPlaceholder() || enabled == null
          ? _value.enabled
          // ignore: cast_nullable_to_non_nullable
          : enabled as bool,
      hasToken: hasToken == const $CopyWithPlaceholder() || hasToken == null
          ? _value.hasToken
          // ignore: cast_nullable_to_non_nullable
          : hasToken as bool,
      webhookUrl: webhookUrl == const $CopyWithPlaceholder()
          ? _value.webhookUrl
          // ignore: cast_nullable_to_non_nullable
          : webhookUrl as String?,
      webhookSecret: webhookSecret == const $CopyWithPlaceholder()
          ? _value.webhookSecret
          // ignore: cast_nullable_to_non_nullable
          : webhookSecret as String?,
      lastSyncedAt: lastSyncedAt == const $CopyWithPlaceholder()
          ? _value.lastSyncedAt
          // ignore: cast_nullable_to_non_nullable
          : lastSyncedAt as DateTime?,
      lastCommit: lastCommit == const $CopyWithPlaceholder()
          ? _value.lastCommit
          // ignore: cast_nullable_to_non_nullable
          : lastCommit as String?,
      lastError: lastError == const $CopyWithPlaceholder()
          ? _value.lastError
          // ignore: cast_nullable_to_non_nullable
          : lastError as String?,
      openPrUrl: openPrUrl == const $CopyWithPlaceholder()
          ? _value.openPrUrl
          // ignore: cast_nullable_to_non_nullable
          : openPrUrl as String?,
    );
  }
}

extension $GitSyncStatusCopyWith on GitSyncStatus {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfGitSyncStatus.copyWith(...)` or `instanceOfGitSyncStatus.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$GitSyncStatusCWProxy get copyWith => _$GitSyncStatusCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GitSyncStatus _$GitSyncStatusFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'GitSyncStatus',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'configured',
            'repo',
            'branch',
            'path',
            'enabled',
            'has_token',
            'webhook_url',
            'webhook_secret',
            'last_synced_at',
            'last_commit',
            'last_error',
            'open_pr_url',
          ],
        );
        final val = GitSyncStatus(
          configured: $checkedConvert('configured', (v) => v as bool),
          repo: $checkedConvert('repo', (v) => v as String?),
          branch: $checkedConvert('branch', (v) => v as String?),
          path: $checkedConvert('path', (v) => v as String?),
          enabled: $checkedConvert('enabled', (v) => v as bool),
          hasToken: $checkedConvert('has_token', (v) => v as bool),
          webhookUrl: $checkedConvert('webhook_url', (v) => v as String?),
          webhookSecret: $checkedConvert('webhook_secret', (v) => v as String?),
          lastSyncedAt: $checkedConvert(
            'last_synced_at',
            (v) => v == null ? null : DateTime.parse(v as String),
          ),
          lastCommit: $checkedConvert('last_commit', (v) => v as String?),
          lastError: $checkedConvert('last_error', (v) => v as String?),
          openPrUrl: $checkedConvert('open_pr_url', (v) => v as String?),
        );
        return val;
      },
      fieldKeyMap: const {
        'hasToken': 'has_token',
        'webhookUrl': 'webhook_url',
        'webhookSecret': 'webhook_secret',
        'lastSyncedAt': 'last_synced_at',
        'lastCommit': 'last_commit',
        'lastError': 'last_error',
        'openPrUrl': 'open_pr_url',
      },
    );

Map<String, dynamic> _$GitSyncStatusToJson(GitSyncStatus instance) =>
    <String, dynamic>{
      'configured': instance.configured,
      'repo': instance.repo,
      'branch': instance.branch,
      'path': instance.path,
      'enabled': instance.enabled,
      'has_token': instance.hasToken,
      'webhook_url': instance.webhookUrl,
      'webhook_secret': instance.webhookSecret,
      'last_synced_at': instance.lastSyncedAt?.toIso8601String(),
      'last_commit': instance.lastCommit,
      'last_error': instance.lastError,
      'open_pr_url': instance.openPrUrl,
    };
