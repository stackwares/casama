//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:kasama_api/src/model/task_priority.dart';
import 'package:kasama_api/src/model/task_status.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'task.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Task {
  /// Returns a new [Task] instance.
  Task({

    required  this.id,

    required  this.title,

    required  this.detailsMd,

    required  this.status,

    required  this.priority,

    required  this.assigneeBotId,

    required  this.assigneeUserId,

    required  this.createdByBotId,

    required  this.createdByUserId,

    required  this.resultMd,

    required  this.dueAt,

    required  this.labels,

    required  this.position,

    required  this.reviewRequired,

    required  this.projectId,

    required  this.milestoneId,

    required  this.parentTaskId,

    required  this.conversationId,

    required  this.comments,

    required  this.updatedAt,

    required  this.createdAt,
  });

  @JsonKey(
    
    name: r'id',
    required: true,
    includeIfNull: false,
  )


  final String id;



  @JsonKey(
    
    name: r'title',
    required: true,
    includeIfNull: false,
  )


  final String title;



  @JsonKey(
    
    name: r'details_md',
    required: true,
    includeIfNull: false,
  )


  final String detailsMd;



  @JsonKey(
    
    name: r'status',
    required: true,
    includeIfNull: false,
  )


  final TaskStatus status;



  @JsonKey(
    
    name: r'priority',
    required: true,
    includeIfNull: false,
  )


  final TaskPriority priority;



  @JsonKey(
    
    name: r'assignee_bot_id',
    required: true,
    includeIfNull: true,
  )


  final String? assigneeBotId;



  @JsonKey(
    
    name: r'assignee_user_id',
    required: true,
    includeIfNull: true,
  )


  final String? assigneeUserId;



  @JsonKey(
    
    name: r'created_by_bot_id',
    required: true,
    includeIfNull: true,
  )


  final String? createdByBotId;



  @JsonKey(
    
    name: r'created_by_user_id',
    required: true,
    includeIfNull: true,
  )


  final String? createdByUserId;



  @JsonKey(
    
    name: r'result_md',
    required: true,
    includeIfNull: true,
  )


  final String? resultMd;



  @JsonKey(
    
    name: r'due_at',
    required: true,
    includeIfNull: true,
  )


  final DateTime? dueAt;



  @JsonKey(
    
    name: r'labels',
    required: true,
    includeIfNull: false,
  )


  final List<String> labels;



  @JsonKey(
    
    name: r'position',
    required: true,
    includeIfNull: false,
  )


  final num position;



  @JsonKey(
    
    name: r'review_required',
    required: true,
    includeIfNull: false,
  )


  final bool reviewRequired;



      /// Its project (D-113)
  @JsonKey(
    
    name: r'project_id',
    required: true,
    includeIfNull: true,
  )


  final String? projectId;



  @JsonKey(
    
    name: r'milestone_id',
    required: true,
    includeIfNull: true,
  )


  final String? milestoneId;



  @JsonKey(
    
    name: r'parent_task_id',
    required: true,
    includeIfNull: true,
  )


  final String? parentTaskId;



  @JsonKey(
    
    name: r'conversation_id',
    required: true,
    includeIfNull: true,
  )


  final String? conversationId;



      /// How many comments the ticket has
  @JsonKey(
    
    name: r'comments',
    required: true,
    includeIfNull: false,
  )


  final int comments;



  @JsonKey(
    
    name: r'updated_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime updatedAt;



  @JsonKey(
    
    name: r'created_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime createdAt;





    @override
    bool operator ==(Object other) => identical(this, other) || other is Task &&
      other.id == id &&
      other.title == title &&
      other.detailsMd == detailsMd &&
      other.status == status &&
      other.priority == priority &&
      other.assigneeBotId == assigneeBotId &&
      other.assigneeUserId == assigneeUserId &&
      other.createdByBotId == createdByBotId &&
      other.createdByUserId == createdByUserId &&
      other.resultMd == resultMd &&
      other.dueAt == dueAt &&
      other.labels == labels &&
      other.position == position &&
      other.reviewRequired == reviewRequired &&
      other.projectId == projectId &&
      other.milestoneId == milestoneId &&
      other.parentTaskId == parentTaskId &&
      other.conversationId == conversationId &&
      other.comments == comments &&
      other.updatedAt == updatedAt &&
      other.createdAt == createdAt;

    @override
    int get hashCode =>
        id.hashCode +
        title.hashCode +
        detailsMd.hashCode +
        status.hashCode +
        priority.hashCode +
        (assigneeBotId == null ? 0 : assigneeBotId.hashCode) +
        (assigneeUserId == null ? 0 : assigneeUserId.hashCode) +
        (createdByBotId == null ? 0 : createdByBotId.hashCode) +
        (createdByUserId == null ? 0 : createdByUserId.hashCode) +
        (resultMd == null ? 0 : resultMd.hashCode) +
        (dueAt == null ? 0 : dueAt.hashCode) +
        labels.hashCode +
        position.hashCode +
        reviewRequired.hashCode +
        (projectId == null ? 0 : projectId.hashCode) +
        (milestoneId == null ? 0 : milestoneId.hashCode) +
        (parentTaskId == null ? 0 : parentTaskId.hashCode) +
        (conversationId == null ? 0 : conversationId.hashCode) +
        comments.hashCode +
        updatedAt.hashCode +
        createdAt.hashCode;

  factory Task.fromJson(Map<String, dynamic> json) => _$TaskFromJson(json);

  Map<String, dynamic> toJson() => _$TaskToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

