//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'agent_import_plan_sources.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AgentImportPlanSources {
  /// Returns a new [AgentImportPlanSources] instance.
  AgentImportPlanSources({

    required  this.skills,

    required  this.routines,

    required  this.memories,
  });

  @JsonKey(
    
    name: r'skills',
    required: true,
    includeIfNull: false,
  )


  final List<String> skills;



  @JsonKey(
    
    name: r'routines',
    required: true,
    includeIfNull: false,
  )


  final List<String> routines;



  @JsonKey(
    
    name: r'memories',
    required: true,
    includeIfNull: false,
  )


  final List<String> memories;





    @override
    bool operator ==(Object other) => identical(this, other) || other is AgentImportPlanSources &&
      other.skills == skills &&
      other.routines == routines &&
      other.memories == memories;

    @override
    int get hashCode =>
        skills.hashCode +
        routines.hashCode +
        memories.hashCode;

  factory AgentImportPlanSources.fromJson(Map<String, dynamic> json) => _$AgentImportPlanSourcesFromJson(json);

  Map<String, dynamic> toJson() => _$AgentImportPlanSourcesToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

