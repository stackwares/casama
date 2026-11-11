//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'project_milestone.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ProjectMilestone {
  /// Returns a new [ProjectMilestone] instance.
  ProjectMilestone({

    required  this.id,

    required  this.name,

    required  this.position,

    required  this.requiresSignoff,

    required  this.status,

    required  this.ticketsDone,

    required  this.ticketsTotal,
  });

  @JsonKey(
    
    name: r'id',
    required: true,
    includeIfNull: false,
  )


  final String id;



  @JsonKey(
    
    name: r'name',
    required: true,
    includeIfNull: false,
  )


  final String name;



  @JsonKey(
    
    name: r'position',
    required: true,
    includeIfNull: false,
  )


  final int position;



  @JsonKey(
    
    name: r'requires_signoff',
    required: true,
    includeIfNull: false,
  )


  final bool requiresSignoff;



  @JsonKey(
    
    name: r'status',
    required: true,
    includeIfNull: false,
  )


  final ProjectMilestoneStatusEnum status;



  @JsonKey(
    
    name: r'tickets_done',
    required: true,
    includeIfNull: false,
  )


  final int ticketsDone;



  @JsonKey(
    
    name: r'tickets_total',
    required: true,
    includeIfNull: false,
  )


  final int ticketsTotal;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ProjectMilestone &&
      other.id == id &&
      other.name == name &&
      other.position == position &&
      other.requiresSignoff == requiresSignoff &&
      other.status == status &&
      other.ticketsDone == ticketsDone &&
      other.ticketsTotal == ticketsTotal;

    @override
    int get hashCode =>
        id.hashCode +
        name.hashCode +
        position.hashCode +
        requiresSignoff.hashCode +
        status.hashCode +
        ticketsDone.hashCode +
        ticketsTotal.hashCode;

  factory ProjectMilestone.fromJson(Map<String, dynamic> json) => _$ProjectMilestoneFromJson(json);

  Map<String, dynamic> toJson() => _$ProjectMilestoneToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum ProjectMilestoneStatusEnum {
@JsonValue(r'open')
open(r'open'),
@JsonValue(r'awaiting_signoff')
awaitingSignoff(r'awaiting_signoff'),
@JsonValue(r'done')
done(r'done');

const ProjectMilestoneStatusEnum(this.value);

final String value;

@override
String toString() => value;
}


