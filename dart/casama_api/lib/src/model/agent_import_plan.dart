//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/agent_import_plan_leftovers_inner.dart';
import 'package:casama_api/src/model/agent_import_plan_sources.dart';
import 'package:casama_api/src/model/agent_import_plan_skipped_inner.dart';
import 'package:casama_api/src/model/bot_template_file.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'agent_import_plan.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AgentImportPlan {
  /// Returns a new [AgentImportPlan] instance.
  AgentImportPlan({

    required  this.id,

    required  this.kind,

    required  this.template,

    required  this.sources,

    required  this.leftovers,

    required  this.skipped,

    required  this.notes,
  });

  @JsonKey(
    
    name: r'id',
    required: true,
    includeIfNull: false,
  )


  final String id;



  @JsonKey(
    
    name: r'kind',
    required: true,
    includeIfNull: false,
  )


  final AgentImportPlanKindEnum kind;



  @JsonKey(
    
    name: r'template',
    required: true,
    includeIfNull: false,
  )


  final BotTemplateFile template;



  @JsonKey(
    
    name: r'sources',
    required: true,
    includeIfNull: false,
  )


  final AgentImportPlanSources sources;



  @JsonKey(
    
    name: r'leftovers',
    required: true,
    includeIfNull: false,
  )


  final List<AgentImportPlanLeftoversInner> leftovers;



  @JsonKey(
    
    name: r'skipped',
    required: true,
    includeIfNull: false,
  )


  final List<AgentImportPlanSkippedInner> skipped;



  @JsonKey(
    
    name: r'notes',
    required: true,
    includeIfNull: false,
  )


  final List<String> notes;





    @override
    bool operator ==(Object other) => identical(this, other) || other is AgentImportPlan &&
      other.id == id &&
      other.kind == kind &&
      other.template == template &&
      other.sources == sources &&
      other.leftovers == leftovers &&
      other.skipped == skipped &&
      other.notes == notes;

    @override
    int get hashCode =>
        id.hashCode +
        kind.hashCode +
        template.hashCode +
        sources.hashCode +
        leftovers.hashCode +
        skipped.hashCode +
        notes.hashCode;

  factory AgentImportPlan.fromJson(Map<String, dynamic> json) => _$AgentImportPlanFromJson(json);

  Map<String, dynamic> toJson() => _$AgentImportPlanToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum AgentImportPlanKindEnum {
@JsonValue(r'openclaw')
openclaw(r'openclaw'),
@JsonValue(r'hermes')
hermes(r'hermes'),
@JsonValue(r'grok_bot')
grokBot(r'grok_bot'),
@JsonValue(r'muse')
muse(r'muse'),
@JsonValue(r'dots')
dots(r'dots'),
@JsonValue(r'duet')
duet(r'duet'),
@JsonValue(r'hark')
hark(r'hark'),
@JsonValue(r'instinct')
instinct(r'instinct'),
@JsonValue(r'other')
other(r'other');

const AgentImportPlanKindEnum(this.value);

final String value;

@override
String toString() => value;
}


