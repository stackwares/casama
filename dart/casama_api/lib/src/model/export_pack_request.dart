//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/export_pack_request_look.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'export_pack_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ExportPackRequest {
  /// Returns a new [ExportPackRequest] instance.
  ExportPackRequest({

    required  this.name,

    required  this.summary,

     this.description,

     this.icon,

    required  this.botIds,

     this.workspaceSkillIds,

     this.look,
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





    @override
    bool operator ==(Object other) => identical(this, other) || other is ExportPackRequest &&
      other.name == name &&
      other.summary == summary &&
      other.description == description &&
      other.icon == icon &&
      other.botIds == botIds &&
      other.workspaceSkillIds == workspaceSkillIds &&
      other.look == look;

    @override
    int get hashCode =>
        name.hashCode +
        summary.hashCode +
        description.hashCode +
        icon.hashCode +
        botIds.hashCode +
        workspaceSkillIds.hashCode +
        look.hashCode;

  factory ExportPackRequest.fromJson(Map<String, dynamic> json) => _$ExportPackRequestFromJson(json);

  Map<String, dynamic> toJson() => _$ExportPackRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

