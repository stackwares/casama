//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'project_run.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ProjectRun {
  /// Returns a new [ProjectRun] instance.
  ProjectRun({

    required  this.id,

    required  this.botId,

    required  this.trigger,

    required  this.status,

    required  this.costUsd,

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
    
    name: r'trigger',
    required: true,
    includeIfNull: false,
  )


  final String trigger;



  @JsonKey(
    
    name: r'status',
    required: true,
    includeIfNull: false,
  )


  final String status;



  @JsonKey(
    
    name: r'cost_usd',
    required: true,
    includeIfNull: false,
  )


  final num costUsd;



  @JsonKey(
    
    name: r'created_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime createdAt;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ProjectRun &&
      other.id == id &&
      other.botId == botId &&
      other.trigger == trigger &&
      other.status == status &&
      other.costUsd == costUsd &&
      other.createdAt == createdAt;

    @override
    int get hashCode =>
        id.hashCode +
        botId.hashCode +
        trigger.hashCode +
        status.hashCode +
        costUsd.hashCode +
        createdAt.hashCode;

  factory ProjectRun.fromJson(Map<String, dynamic> json) => _$ProjectRunFromJson(json);

  Map<String, dynamic> toJson() => _$ProjectRunToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

