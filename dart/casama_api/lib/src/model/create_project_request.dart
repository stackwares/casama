//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'create_project_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CreateProjectRequest {
  /// Returns a new [CreateProjectRequest] instance.
  CreateProjectRequest({

    required  this.orgId,

    required  this.title,

     this.goalMd,

     this.doneCriteriaMd,

    required  this.leadBotId,

     this.budgetUsd,

     this.deadlineAt,

     this.autonomous,

     this.conversationId,
  });

  @JsonKey(
    
    name: r'org_id',
    required: true,
    includeIfNull: false,
  )


  final String orgId;



  @JsonKey(
    
    name: r'title',
    required: true,
    includeIfNull: false,
  )


  final String title;



      /// Needed when the project works by itself
  @JsonKey(
    
    name: r'goal_md',
    required: false,
    includeIfNull: false,
  )


  final String? goalMd;



  @JsonKey(
    
    name: r'done_criteria_md',
    required: false,
    includeIfNull: false,
  )


  final String? doneCriteriaMd;



  @JsonKey(
    
    name: r'lead_bot_id',
    required: true,
    includeIfNull: false,
  )


  final String leadBotId;



          // minimum: 0
          // maximum: 10000
  @JsonKey(
    
    name: r'budget_usd',
    required: false,
    includeIfNull: false,
  )


  final num? budgetUsd;



  @JsonKey(
    
    name: r'deadline_at',
    required: false,
    includeIfNull: false,
  )


  final DateTime? deadlineAt;



      /// true (the default, as before D-295): the lead bot drafts a plan for you to approve, then works by itself. false: a project you work on together in its chat
  @JsonKey(
    
    name: r'autonomous',
    required: false,
    includeIfNull: false,
  )


  final bool? autonomous;



      /// With autonomous false: make this topic of yours the project's chat, and file what was made in it under the project. Without it the project gets a new topic
  @JsonKey(
    
    name: r'conversation_id',
    required: false,
    includeIfNull: false,
  )


  final String? conversationId;





    @override
    bool operator ==(Object other) => identical(this, other) || other is CreateProjectRequest &&
      other.orgId == orgId &&
      other.title == title &&
      other.goalMd == goalMd &&
      other.doneCriteriaMd == doneCriteriaMd &&
      other.leadBotId == leadBotId &&
      other.budgetUsd == budgetUsd &&
      other.deadlineAt == deadlineAt &&
      other.autonomous == autonomous &&
      other.conversationId == conversationId;

    @override
    int get hashCode =>
        orgId.hashCode +
        title.hashCode +
        goalMd.hashCode +
        doneCriteriaMd.hashCode +
        leadBotId.hashCode +
        (budgetUsd == null ? 0 : budgetUsd.hashCode) +
        (deadlineAt == null ? 0 : deadlineAt.hashCode) +
        autonomous.hashCode +
        conversationId.hashCode;

  factory CreateProjectRequest.fromJson(Map<String, dynamic> json) => _$CreateProjectRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CreateProjectRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

