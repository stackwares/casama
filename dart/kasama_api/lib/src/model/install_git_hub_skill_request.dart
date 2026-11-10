//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'install_git_hub_skill_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class InstallGitHubSkillRequest {
  /// Returns a new [InstallGitHubSkillRequest] instance.
  InstallGitHubSkillRequest({

    required  this.orgId,

     this.botId,

    required  this.url,

    required  this.commit,
  });

  @JsonKey(
    
    name: r'org_id',
    required: true,
    includeIfNull: false,
  )


  final String orgId;



  @JsonKey(
    
    name: r'bot_id',
    required: false,
    includeIfNull: false,
  )


  final String? botId;



  @JsonKey(
    
    name: r'url',
    required: true,
    includeIfNull: false,
  )


  final String url;



  @JsonKey(
    
    name: r'commit',
    required: true,
    includeIfNull: false,
  )


  final String commit;





    @override
    bool operator ==(Object other) => identical(this, other) || other is InstallGitHubSkillRequest &&
      other.orgId == orgId &&
      other.botId == botId &&
      other.url == url &&
      other.commit == commit;

    @override
    int get hashCode =>
        orgId.hashCode +
        botId.hashCode +
        url.hashCode +
        commit.hashCode;

  factory InstallGitHubSkillRequest.fromJson(Map<String, dynamic> json) => _$InstallGitHubSkillRequestFromJson(json);

  Map<String, dynamic> toJson() => _$InstallGitHubSkillRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

