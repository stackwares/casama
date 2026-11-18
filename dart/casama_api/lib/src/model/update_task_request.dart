//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/task_priority.dart';
import 'package:casama_api/src/model/task_status.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'update_task_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class UpdateTaskRequest {
  /// Returns a new [UpdateTaskRequest] instance.
  UpdateTaskRequest({

     this.title,

     this.detailsMd,

     this.status,

     this.priority,

     this.assigneeBotId,

     this.assigneeUserId,

     this.dueAt,

     this.labels,

     this.reviewRequired,

     this.position,
  });

  @JsonKey(
    
    name: r'title',
    required: false,
    includeIfNull: false,
  )


  final String? title;



  @JsonKey(
    
    name: r'details_md',
    required: false,
    includeIfNull: false,
  )


  final String? detailsMd;



  @JsonKey(
    
    name: r'status',
    required: false,
    includeIfNull: false,
  )


  final TaskStatus? status;



  @JsonKey(
    
    name: r'priority',
    required: false,
    includeIfNull: false,
  )


  final TaskPriority? priority;



      /// The bot starts on it at once
  @JsonKey(
    
    name: r'assignee_bot_id',
    required: false,
    includeIfNull: false,
  )


  final String? assigneeBotId;



  @JsonKey(
    
    name: r'assignee_user_id',
    required: false,
    includeIfNull: false,
  )


  final String? assigneeUserId;



  @JsonKey(
    
    name: r'due_at',
    required: false,
    includeIfNull: false,
  )


  final DateTime? dueAt;



  @JsonKey(
    
    name: r'labels',
    required: false,
    includeIfNull: false,
  )


  final List<String>? labels;



  @JsonKey(
    
    name: r'review_required',
    required: false,
    includeIfNull: false,
  )


  final bool? reviewRequired;



  @JsonKey(
    
    name: r'position',
    required: false,
    includeIfNull: false,
  )


  final num? position;





    @override
    bool operator ==(Object other) => identical(this, other) || other is UpdateTaskRequest &&
      other.title == title &&
      other.detailsMd == detailsMd &&
      other.status == status &&
      other.priority == priority &&
      other.assigneeBotId == assigneeBotId &&
      other.assigneeUserId == assigneeUserId &&
      other.dueAt == dueAt &&
      other.labels == labels &&
      other.reviewRequired == reviewRequired &&
      other.position == position;

    @override
    int get hashCode =>
        title.hashCode +
        detailsMd.hashCode +
        status.hashCode +
        priority.hashCode +
        (assigneeBotId == null ? 0 : assigneeBotId.hashCode) +
        (assigneeUserId == null ? 0 : assigneeUserId.hashCode) +
        (dueAt == null ? 0 : dueAt.hashCode) +
        labels.hashCode +
        reviewRequired.hashCode +
        position.hashCode;

  factory UpdateTaskRequest.fromJson(Map<String, dynamic> json) => _$UpdateTaskRequestFromJson(json);

  Map<String, dynamic> toJson() => _$UpdateTaskRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

