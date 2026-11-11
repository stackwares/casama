//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'agent_import_plan_skipped_inner.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AgentImportPlanSkippedInner {
  /// Returns a new [AgentImportPlanSkippedInner] instance.
  AgentImportPlanSkippedInner({

    required  this.path,

    required  this.reason,
  });

  @JsonKey(
    
    name: r'path',
    required: true,
    includeIfNull: false,
  )


  final String path;



  @JsonKey(
    
    name: r'reason',
    required: true,
    includeIfNull: false,
  )


  final String reason;





    @override
    bool operator ==(Object other) => identical(this, other) || other is AgentImportPlanSkippedInner &&
      other.path == path &&
      other.reason == reason;

    @override
    int get hashCode =>
        path.hashCode +
        reason.hashCode;

  factory AgentImportPlanSkippedInner.fromJson(Map<String, dynamic> json) => _$AgentImportPlanSkippedInnerFromJson(json);

  Map<String, dynamic> toJson() => _$AgentImportPlanSkippedInnerToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

