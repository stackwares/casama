//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:kasama_api/src/model/visibility.dart';
import 'package:kasama_api/src/model/autonomy.dart';
import 'package:kasama_api/src/model/bot_budget.dart';
import 'package:kasama_api/src/model/model_policy.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'create_bot_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CreateBotRequest {
  /// Returns a new [CreateBotRequest] instance.
  CreateBotRequest({

    required  this.orgId,

    required  this.name,

     this.personaMd,

     this.avatarUrl,

     this.modelPolicy,

     this.autonomy,

     this.visibility,

     this.budget,

     this.templateId,
  });

  @JsonKey(
    
    name: r'org_id',
    required: true,
    includeIfNull: false,
  )


  final String orgId;



  @JsonKey(
    
    name: r'name',
    required: true,
    includeIfNull: false,
  )


  final String name;



  @JsonKey(
    
    name: r'persona_md',
    required: false,
    includeIfNull: false,
  )


  final String? personaMd;



  @JsonKey(
    
    name: r'avatar_url',
    required: false,
    includeIfNull: false,
  )


  final String? avatarUrl;



  @JsonKey(
    
    name: r'model_policy',
    required: false,
    includeIfNull: false,
  )


  final ModelPolicy? modelPolicy;



  @JsonKey(
    
    name: r'autonomy',
    required: false,
    includeIfNull: false,
  )


  final Autonomy? autonomy;



  @JsonKey(
    
    name: r'visibility',
    required: false,
    includeIfNull: false,
  )


  final Visibility? visibility;



  @JsonKey(
    
    name: r'budget',
    required: false,
    includeIfNull: false,
  )


  final BotBudget? budget;



      /// Start from a starter template (persona, skills, routines)
  @JsonKey(
    
    name: r'template_id',
    required: false,
    includeIfNull: false,
  )


  final String? templateId;





    @override
    bool operator ==(Object other) => identical(this, other) || other is CreateBotRequest &&
      other.orgId == orgId &&
      other.name == name &&
      other.personaMd == personaMd &&
      other.avatarUrl == avatarUrl &&
      other.modelPolicy == modelPolicy &&
      other.autonomy == autonomy &&
      other.visibility == visibility &&
      other.budget == budget &&
      other.templateId == templateId;

    @override
    int get hashCode =>
        orgId.hashCode +
        name.hashCode +
        personaMd.hashCode +
        avatarUrl.hashCode +
        modelPolicy.hashCode +
        autonomy.hashCode +
        visibility.hashCode +
        budget.hashCode +
        templateId.hashCode;

  factory CreateBotRequest.fromJson(Map<String, dynamic> json) => _$CreateBotRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CreateBotRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

