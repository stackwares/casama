//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'update_project_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class UpdateProjectRequest {
  /// Returns a new [UpdateProjectRequest] instance.
  UpdateProjectRequest({

     this.title,

     this.status,

     this.budgetUsd,

     this.deadlineAt,

     this.planMd,

     this.goalMd,

     this.doneCriteriaMd,

     this.autonomous,
  });

  @JsonKey(
    
    name: r'title',
    required: false,
    includeIfNull: false,
  )


  final String? title;



      /// Resume, pause, cancel or finish. A finished project you work on together can be made active again
  @JsonKey(
    
    name: r'status',
    required: false,
    includeIfNull: false,
  )


  final UpdateProjectRequestStatusEnum? status;



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



  @JsonKey(
    
    name: r'plan_md',
    required: false,
    includeIfNull: false,
  )


  final String? planMd;



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



      /// true: the lead bot drafts a plan for you to approve, then works by itself (needs a goal). false: back to working on it together; nothing more starts by itself
  @JsonKey(
    
    name: r'autonomous',
    required: false,
    includeIfNull: false,
  )


  final bool? autonomous;





    @override
    bool operator ==(Object other) => identical(this, other) || other is UpdateProjectRequest &&
      other.title == title &&
      other.status == status &&
      other.budgetUsd == budgetUsd &&
      other.deadlineAt == deadlineAt &&
      other.planMd == planMd &&
      other.goalMd == goalMd &&
      other.doneCriteriaMd == doneCriteriaMd &&
      other.autonomous == autonomous;

    @override
    int get hashCode =>
        title.hashCode +
        status.hashCode +
        (budgetUsd == null ? 0 : budgetUsd.hashCode) +
        (deadlineAt == null ? 0 : deadlineAt.hashCode) +
        planMd.hashCode +
        goalMd.hashCode +
        doneCriteriaMd.hashCode +
        autonomous.hashCode;

  factory UpdateProjectRequest.fromJson(Map<String, dynamic> json) => _$UpdateProjectRequestFromJson(json);

  Map<String, dynamic> toJson() => _$UpdateProjectRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

/// Resume, pause, cancel or finish. A finished project you work on together can be made active again
enum UpdateProjectRequestStatusEnum {
    /// Resume, pause, cancel or finish. A finished project you work on together can be made active again
@JsonValue(r'active')
active(r'active'),
    /// Resume, pause, cancel or finish. A finished project you work on together can be made active again
@JsonValue(r'paused')
paused(r'paused'),
    /// Resume, pause, cancel or finish. A finished project you work on together can be made active again
@JsonValue(r'cancelled')
cancelled(r'cancelled'),
    /// Resume, pause, cancel or finish. A finished project you work on together can be made active again
@JsonValue(r'done')
done(r'done');

const UpdateProjectRequestStatusEnum(this.value);

final String value;

@override
String toString() => value;
}


