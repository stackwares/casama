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
  });

  @JsonKey(
    
    name: r'title',
    required: false,
    includeIfNull: false,
  )


  final String? title;



      /// Resume, pause or cancel
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





    @override
    bool operator ==(Object other) => identical(this, other) || other is UpdateProjectRequest &&
      other.title == title &&
      other.status == status &&
      other.budgetUsd == budgetUsd &&
      other.deadlineAt == deadlineAt &&
      other.planMd == planMd;

    @override
    int get hashCode =>
        title.hashCode +
        status.hashCode +
        (budgetUsd == null ? 0 : budgetUsd.hashCode) +
        (deadlineAt == null ? 0 : deadlineAt.hashCode) +
        planMd.hashCode;

  factory UpdateProjectRequest.fromJson(Map<String, dynamic> json) => _$UpdateProjectRequestFromJson(json);

  Map<String, dynamic> toJson() => _$UpdateProjectRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

/// Resume, pause or cancel
enum UpdateProjectRequestStatusEnum {
    /// Resume, pause or cancel
@JsonValue(r'active')
active(r'active'),
    /// Resume, pause or cancel
@JsonValue(r'paused')
paused(r'paused'),
    /// Resume, pause or cancel
@JsonValue(r'cancelled')
cancelled(r'cancelled');

const UpdateProjectRequestStatusEnum(this.value);

final String value;

@override
String toString() => value;
}


