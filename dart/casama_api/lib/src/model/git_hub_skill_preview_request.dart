//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'git_hub_skill_preview_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class GitHubSkillPreviewRequest {
  /// Returns a new [GitHubSkillPreviewRequest] instance.
  GitHubSkillPreviewRequest({

    required  this.orgId,

    required  this.url,
  });

  @JsonKey(
    
    name: r'org_id',
    required: true,
    includeIfNull: false,
  )


  final String orgId;



  @JsonKey(
    
    name: r'url',
    required: true,
    includeIfNull: false,
  )


  final String url;





    @override
    bool operator ==(Object other) => identical(this, other) || other is GitHubSkillPreviewRequest &&
      other.orgId == orgId &&
      other.url == url;

    @override
    int get hashCode =>
        orgId.hashCode +
        url.hashCode;

  factory GitHubSkillPreviewRequest.fromJson(Map<String, dynamic> json) => _$GitHubSkillPreviewRequestFromJson(json);

  Map<String, dynamic> toJson() => _$GitHubSkillPreviewRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

