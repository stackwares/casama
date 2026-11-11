//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'git_sync_status.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class GitSyncStatus {
  /// Returns a new [GitSyncStatus] instance.
  GitSyncStatus({

    required  this.configured,

    required  this.repo,

    required  this.branch,

    required  this.path,

    required  this.enabled,

    required  this.hasToken,

    required  this.webhookUrl,

    required  this.webhookSecret,

    required  this.lastSyncedAt,

    required  this.lastCommit,

    required  this.lastError,

    required  this.openPrUrl,
  });

  @JsonKey(
    
    name: r'configured',
    required: true,
    includeIfNull: false,
  )


  final bool configured;



  @JsonKey(
    
    name: r'repo',
    required: true,
    includeIfNull: true,
  )


  final String? repo;



  @JsonKey(
    
    name: r'branch',
    required: true,
    includeIfNull: true,
  )


  final String? branch;



  @JsonKey(
    
    name: r'path',
    required: true,
    includeIfNull: true,
  )


  final String? path;



  @JsonKey(
    
    name: r'enabled',
    required: true,
    includeIfNull: false,
  )


  final bool enabled;



  @JsonKey(
    
    name: r'has_token',
    required: true,
    includeIfNull: false,
  )


  final bool hasToken;



  @JsonKey(
    
    name: r'webhook_url',
    required: true,
    includeIfNull: true,
  )


  final String? webhookUrl;



  @JsonKey(
    
    name: r'webhook_secret',
    required: true,
    includeIfNull: true,
  )


  final String? webhookSecret;



  @JsonKey(
    
    name: r'last_synced_at',
    required: true,
    includeIfNull: true,
  )


  final DateTime? lastSyncedAt;



  @JsonKey(
    
    name: r'last_commit',
    required: true,
    includeIfNull: true,
  )


  final String? lastCommit;



  @JsonKey(
    
    name: r'last_error',
    required: true,
    includeIfNull: true,
  )


  final String? lastError;



  @JsonKey(
    
    name: r'open_pr_url',
    required: true,
    includeIfNull: true,
  )


  final String? openPrUrl;





    @override
    bool operator ==(Object other) => identical(this, other) || other is GitSyncStatus &&
      other.configured == configured &&
      other.repo == repo &&
      other.branch == branch &&
      other.path == path &&
      other.enabled == enabled &&
      other.hasToken == hasToken &&
      other.webhookUrl == webhookUrl &&
      other.webhookSecret == webhookSecret &&
      other.lastSyncedAt == lastSyncedAt &&
      other.lastCommit == lastCommit &&
      other.lastError == lastError &&
      other.openPrUrl == openPrUrl;

    @override
    int get hashCode =>
        configured.hashCode +
        (repo == null ? 0 : repo.hashCode) +
        (branch == null ? 0 : branch.hashCode) +
        (path == null ? 0 : path.hashCode) +
        enabled.hashCode +
        hasToken.hashCode +
        (webhookUrl == null ? 0 : webhookUrl.hashCode) +
        (webhookSecret == null ? 0 : webhookSecret.hashCode) +
        (lastSyncedAt == null ? 0 : lastSyncedAt.hashCode) +
        (lastCommit == null ? 0 : lastCommit.hashCode) +
        (lastError == null ? 0 : lastError.hashCode) +
        (openPrUrl == null ? 0 : openPrUrl.hashCode);

  factory GitSyncStatus.fromJson(Map<String, dynamic> json) => _$GitSyncStatusFromJson(json);

  Map<String, dynamic> toJson() => _$GitSyncStatusToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

