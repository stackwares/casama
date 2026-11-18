//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/creation.dart';
import 'package:casama_api/src/model/project_milestone.dart';
import 'package:casama_api/src/model/project_status.dart';
import 'package:casama_api/src/model/project_run.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'project_detail.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ProjectDetail {
  /// Returns a new [ProjectDetail] instance.
  ProjectDetail({

    required  this.id,

    required  this.orgId,

    required  this.slug,

    required  this.title,

    required  this.goalMd,

    required  this.doneCriteriaMd,

    required  this.status,

    required  this.planStatus,

    required  this.statusReason,

    required  this.leadBotId,

    required  this.ownerUserId,

    required  this.conversationId,

    required  this.budgetUsd,

    required  this.spentUsd,

    required  this.deadlineAt,

    required  this.planMd,

    required  this.sessions,

    required  this.createdAt,

     this.autonomous,

     this.personal,

     this.folder,

     this.creationsCount,

     this.latestCreation,

     this.canSteer,

    required  this.milestones,

    required  this.runs,
  });

  @JsonKey(
    
    name: r'id',
    required: true,
    includeIfNull: false,
  )


  final String id;



  @JsonKey(
    
    name: r'org_id',
    required: true,
    includeIfNull: false,
  )


  final String orgId;



  @JsonKey(
    
    name: r'slug',
    required: true,
    includeIfNull: false,
  )


  final String slug;



  @JsonKey(
    
    name: r'title',
    required: true,
    includeIfNull: false,
  )


  final String title;



  @JsonKey(
    
    name: r'goal_md',
    required: true,
    includeIfNull: false,
  )


  final String goalMd;



  @JsonKey(
    
    name: r'done_criteria_md',
    required: true,
    includeIfNull: false,
  )


  final String doneCriteriaMd;



  @JsonKey(
    
    name: r'status',
    required: true,
    includeIfNull: false,
  )


  final ProjectStatus status;



  @JsonKey(
    
    name: r'plan_status',
    required: true,
    includeIfNull: false,
  )


  final ProjectDetailPlanStatusEnum planStatus;



  @JsonKey(
    
    name: r'status_reason',
    required: true,
    includeIfNull: true,
  )


  final String? statusReason;



  @JsonKey(
    
    name: r'lead_bot_id',
    required: true,
    includeIfNull: false,
  )


  final String leadBotId;



  @JsonKey(
    
    name: r'owner_user_id',
    required: true,
    includeIfNull: true,
  )


  final String? ownerUserId;



  @JsonKey(
    
    name: r'conversation_id',
    required: true,
    includeIfNull: true,
  )


  final String? conversationId;



  @JsonKey(
    
    name: r'budget_usd',
    required: true,
    includeIfNull: true,
  )


  final num? budgetUsd;



  @JsonKey(
    
    name: r'spent_usd',
    required: true,
    includeIfNull: false,
  )


  final num spentUsd;



  @JsonKey(
    
    name: r'deadline_at',
    required: true,
    includeIfNull: true,
  )


  final DateTime? deadlineAt;



  @JsonKey(
    
    name: r'plan_md',
    required: true,
    includeIfNull: false,
  )


  final String planMd;



  @JsonKey(
    
    name: r'sessions',
    required: true,
    includeIfNull: false,
  )


  final int sessions;



  @JsonKey(
    
    name: r'created_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime createdAt;



      /// Plans for your approval, then works by itself in sessions (D-113). False: worked on together in its chat (D-295). Absent on older servers, where every project is autonomous
  @JsonKey(
    
    name: r'autonomous',
    required: false,
    includeIfNull: false,
  )


  final bool? autonomous;



      /// Grew out of a person's own chat: seen by them and by whoever can open its chat, not the whole workspace
  @JsonKey(
    
    name: r'personal',
    required: false,
    includeIfNull: false,
  )


  final bool? personal;



      /// Where its files live on the lead bot's computer, under the home folder (the folder is made when the bot first saves something there)
  @JsonKey(
    
    name: r'folder',
    required: false,
    includeIfNull: false,
  )


  final String? folder;



      /// How many things in the Library are filed under it, that you can see
  @JsonKey(
    
    name: r'creations_count',
    required: false,
    includeIfNull: false,
  )


  final int? creationsCount;



  @JsonKey(
    
    name: r'latest_creation',
    required: false,
    includeIfNull: false,
  )


  final Creation? latestCreation;



      /// Whether you may change it: its owner, an admin or the lead bot's managers
  @JsonKey(
    
    name: r'can_steer',
    required: false,
    includeIfNull: false,
  )


  final bool? canSteer;



  @JsonKey(
    
    name: r'milestones',
    required: true,
    includeIfNull: false,
  )


  final List<ProjectMilestone> milestones;



  @JsonKey(
    
    name: r'runs',
    required: true,
    includeIfNull: false,
  )


  final List<ProjectRun> runs;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ProjectDetail &&
      other.id == id &&
      other.orgId == orgId &&
      other.slug == slug &&
      other.title == title &&
      other.goalMd == goalMd &&
      other.doneCriteriaMd == doneCriteriaMd &&
      other.status == status &&
      other.planStatus == planStatus &&
      other.statusReason == statusReason &&
      other.leadBotId == leadBotId &&
      other.ownerUserId == ownerUserId &&
      other.conversationId == conversationId &&
      other.budgetUsd == budgetUsd &&
      other.spentUsd == spentUsd &&
      other.deadlineAt == deadlineAt &&
      other.planMd == planMd &&
      other.sessions == sessions &&
      other.createdAt == createdAt &&
      other.autonomous == autonomous &&
      other.personal == personal &&
      other.folder == folder &&
      other.creationsCount == creationsCount &&
      other.latestCreation == latestCreation &&
      other.canSteer == canSteer &&
      other.milestones == milestones &&
      other.runs == runs;

    @override
    int get hashCode =>
        id.hashCode +
        orgId.hashCode +
        slug.hashCode +
        title.hashCode +
        goalMd.hashCode +
        doneCriteriaMd.hashCode +
        status.hashCode +
        planStatus.hashCode +
        (statusReason == null ? 0 : statusReason.hashCode) +
        leadBotId.hashCode +
        (ownerUserId == null ? 0 : ownerUserId.hashCode) +
        (conversationId == null ? 0 : conversationId.hashCode) +
        (budgetUsd == null ? 0 : budgetUsd.hashCode) +
        spentUsd.hashCode +
        (deadlineAt == null ? 0 : deadlineAt.hashCode) +
        planMd.hashCode +
        sessions.hashCode +
        createdAt.hashCode +
        autonomous.hashCode +
        personal.hashCode +
        folder.hashCode +
        creationsCount.hashCode +
        latestCreation.hashCode +
        canSteer.hashCode +
        milestones.hashCode +
        runs.hashCode;

  factory ProjectDetail.fromJson(Map<String, dynamic> json) => _$ProjectDetailFromJson(json);

  Map<String, dynamic> toJson() => _$ProjectDetailToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum ProjectDetailPlanStatusEnum {
@JsonValue(r'draft')
draft(r'draft'),
@JsonValue(r'proposed')
proposed(r'proposed'),
@JsonValue(r'approved')
approved(r'approved');

const ProjectDetailPlanStatusEnum(this.value);

final String value;

@override
String toString() => value;
}


