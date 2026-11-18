//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'accept_skill_proposal_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AcceptSkillProposalRequest {
  /// Returns a new [AcceptSkillProposalRequest] instance.
  AcceptSkillProposalRequest({

     this.name,

     this.description,

     this.bodyMd,
  });

  @JsonKey(
    
    name: r'name',
    required: false,
    includeIfNull: false,
  )


  final String? name;



  @JsonKey(
    
    name: r'description',
    required: false,
    includeIfNull: false,
  )


  final String? description;



  @JsonKey(
    
    name: r'body_md',
    required: false,
    includeIfNull: false,
  )


  final String? bodyMd;





    @override
    bool operator ==(Object other) => identical(this, other) || other is AcceptSkillProposalRequest &&
      other.name == name &&
      other.description == description &&
      other.bodyMd == bodyMd;

    @override
    int get hashCode =>
        name.hashCode +
        description.hashCode +
        bodyMd.hashCode;

  factory AcceptSkillProposalRequest.fromJson(Map<String, dynamic> json) => _$AcceptSkillProposalRequestFromJson(json);

  Map<String, dynamic> toJson() => _$AcceptSkillProposalRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

