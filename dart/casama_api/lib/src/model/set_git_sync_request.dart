//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'set_git_sync_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SetGitSyncRequest {
  /// Returns a new [SetGitSyncRequest] instance.
  SetGitSyncRequest({

    required  this.repo,

     this.branch,

     this.path,

     this.enabled,
  });

  @JsonKey(
    
    name: r'repo',
    required: true,
    includeIfNull: false,
  )


  final String repo;



  @JsonKey(
    
    name: r'branch',
    required: false,
    includeIfNull: false,
  )


  final String? branch;



  @JsonKey(
    
    name: r'path',
    required: false,
    includeIfNull: false,
  )


  final String? path;



  @JsonKey(
    
    name: r'enabled',
    required: false,
    includeIfNull: false,
  )


  final bool? enabled;





    @override
    bool operator ==(Object other) => identical(this, other) || other is SetGitSyncRequest &&
      other.repo == repo &&
      other.branch == branch &&
      other.path == path &&
      other.enabled == enabled;

    @override
    int get hashCode =>
        repo.hashCode +
        branch.hashCode +
        path.hashCode +
        enabled.hashCode;

  factory SetGitSyncRequest.fromJson(Map<String, dynamic> json) => _$SetGitSyncRequestFromJson(json);

  Map<String, dynamic> toJson() => _$SetGitSyncRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

