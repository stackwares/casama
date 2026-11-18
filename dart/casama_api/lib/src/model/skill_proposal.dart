//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'skill_proposal.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SkillProposal {
  /// Returns a new [SkillProposal] instance.
  SkillProposal({

    required  this.id,

    required  this.botId,

    required  this.kind,

    required  this.skillId,

    required  this.name,

    required  this.description,

    required  this.bodyMd,

    required  this.previousBodyMd,

    required  this.tools,

    required  this.reason,

    required  this.status,

    required  this.createdAt,
  });

  @JsonKey(
    
    name: r'id',
    required: true,
    includeIfNull: false,
  )


  final String id;



  @JsonKey(
    
    name: r'bot_id',
    required: true,
    includeIfNull: false,
  )


  final String botId;



  @JsonKey(
    
    name: r'kind',
    required: true,
    includeIfNull: false,
  )


  final SkillProposalKindEnum kind;



  @JsonKey(
    
    name: r'skill_id',
    required: true,
    includeIfNull: true,
  )


  final String? skillId;



  @JsonKey(
    
    name: r'name',
    required: true,
    includeIfNull: false,
  )


  final String name;



  @JsonKey(
    
    name: r'description',
    required: true,
    includeIfNull: false,
  )


  final String description;



  @JsonKey(
    
    name: r'body_md',
    required: true,
    includeIfNull: false,
  )


  final String bodyMd;



  @JsonKey(
    
    name: r'previous_body_md',
    required: true,
    includeIfNull: true,
  )


  final String? previousBodyMd;



  @JsonKey(
    
    name: r'tools',
    required: true,
    includeIfNull: false,
  )


  final List<String> tools;



  @JsonKey(
    
    name: r'reason',
    required: true,
    includeIfNull: false,
  )


  final String reason;



  @JsonKey(
    
    name: r'status',
    required: true,
    includeIfNull: false,
  )


  final SkillProposalStatusEnum status;



  @JsonKey(
    
    name: r'created_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime createdAt;





    @override
    bool operator ==(Object other) => identical(this, other) || other is SkillProposal &&
      other.id == id &&
      other.botId == botId &&
      other.kind == kind &&
      other.skillId == skillId &&
      other.name == name &&
      other.description == description &&
      other.bodyMd == bodyMd &&
      other.previousBodyMd == previousBodyMd &&
      other.tools == tools &&
      other.reason == reason &&
      other.status == status &&
      other.createdAt == createdAt;

    @override
    int get hashCode =>
        id.hashCode +
        botId.hashCode +
        kind.hashCode +
        (skillId == null ? 0 : skillId.hashCode) +
        name.hashCode +
        description.hashCode +
        bodyMd.hashCode +
        (previousBodyMd == null ? 0 : previousBodyMd.hashCode) +
        tools.hashCode +
        reason.hashCode +
        status.hashCode +
        createdAt.hashCode;

  factory SkillProposal.fromJson(Map<String, dynamic> json) => _$SkillProposalFromJson(json);

  Map<String, dynamic> toJson() => _$SkillProposalToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum SkillProposalKindEnum {
@JsonValue(r'new')
new_(r'new'),
@JsonValue(r'edit')
edit(r'edit');

const SkillProposalKindEnum(this.value);

final String value;

@override
String toString() => value;
}



enum SkillProposalStatusEnum {
@JsonValue(r'pending')
pending(r'pending'),
@JsonValue(r'accepted')
accepted(r'accepted'),
@JsonValue(r'dismissed')
dismissed(r'dismissed'),
@JsonValue(r'applied')
applied(r'applied');

const SkillProposalStatusEnum(this.value);

final String value;

@override
String toString() => value;
}


