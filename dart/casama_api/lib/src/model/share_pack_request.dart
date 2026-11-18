//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/export_pack_request_look.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'share_pack_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SharePackRequest {
  /// Returns a new [SharePackRequest] instance.
  SharePackRequest({

    required  this.name,

    required  this.summary,

     this.description,

     this.icon,

    required  this.botIds,

     this.workspaceSkillIds,

     this.look,

     this.ignoreFindings,
  });

  @JsonKey(
    
    name: r'name',
    required: true,
    includeIfNull: false,
  )


  final String name;



  @JsonKey(
    
    name: r'summary',
    required: true,
    includeIfNull: false,
  )


  final String summary;



  @JsonKey(
    
    name: r'description',
    required: false,
    includeIfNull: false,
  )


  final String? description;



  @JsonKey(
    
    name: r'icon',
    required: false,
    includeIfNull: false,
  )


  final String? icon;



  @JsonKey(
    
    name: r'bot_ids',
    required: true,
    includeIfNull: false,
  )


  final List<String> botIds;



  @JsonKey(
    
    name: r'workspace_skill_ids',
    required: false,
    includeIfNull: false,
  )


  final List<String>? workspaceSkillIds;



  @JsonKey(
    
    name: r'look',
    required: false,
    includeIfNull: false,
  )


  final ExportPackRequestLook? look;



      /// Share even though lines look like keys (after checking them)
  @JsonKey(
    
    name: r'ignore_findings',
    required: false,
    includeIfNull: false,
  )


  final bool? ignoreFindings;





    @override
    bool operator ==(Object other) => identical(this, other) || other is SharePackRequest &&
      other.name == name &&
      other.summary == summary &&
      other.description == description &&
      other.icon == icon &&
      other.botIds == botIds &&
      other.workspaceSkillIds == workspaceSkillIds &&
      other.look == look &&
      other.ignoreFindings == ignoreFindings;

    @override
    int get hashCode =>
        name.hashCode +
        summary.hashCode +
        description.hashCode +
        icon.hashCode +
        botIds.hashCode +
        workspaceSkillIds.hashCode +
        look.hashCode +
        ignoreFindings.hashCode;

  factory SharePackRequest.fromJson(Map<String, dynamic> json) => _$SharePackRequestFromJson(json);

  Map<String, dynamic> toJson() => _$SharePackRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

