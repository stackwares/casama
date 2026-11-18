//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/pack_bot_preview_knowledge_inner.dart';
import 'package:casama_api/src/model/pack_bot_preview_rules_inner.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'pack_bot_preview.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PackBotPreview {
  /// Returns a new [PackBotPreview] instance.
  PackBotPreview({

    required  this.id,

    required  this.name,

    required  this.description,

    required  this.icon,

    required  this.mascot,

    required  this.autonomy,

    required  this.persona,

    required  this.starters,

    required  this.skills,

    required  this.routines,

    required  this.tools,

     this.rules,

     this.knowledge,
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
    
    name: r'description',
    required: true,
    includeIfNull: false,
  )


  final String description;



  @JsonKey(
    
    name: r'icon',
    required: true,
    includeIfNull: false,
  )


  final String icon;



  @JsonKey(
    
    name: r'mascot',
    required: true,
    includeIfNull: false,
  )


  final String mascot;



  @JsonKey(
    
    name: r'autonomy',
    required: true,
    includeIfNull: false,
  )


  final PackBotPreviewAutonomyEnum autonomy;



  @JsonKey(
    
    name: r'persona',
    required: true,
    includeIfNull: false,
  )


  final String persona;



  @JsonKey(
    
    name: r'starters',
    required: true,
    includeIfNull: false,
  )


  final List<String> starters;



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
    
    name: r'tools',
    required: true,
    includeIfNull: false,
  )


  final List<String> tools;



      /// Rules that narrow what the bot may do
  @JsonKey(
    
    name: r'rules',
    required: false,
    includeIfNull: false,
  )


  final List<PackBotPreviewRulesInner>? rules;



  @JsonKey(
    
    name: r'knowledge',
    required: false,
    includeIfNull: false,
  )


  final List<PackBotPreviewKnowledgeInner>? knowledge;





    @override
    bool operator ==(Object other) => identical(this, other) || other is PackBotPreview &&
      other.id == id &&
      other.name == name &&
      other.description == description &&
      other.icon == icon &&
      other.mascot == mascot &&
      other.autonomy == autonomy &&
      other.persona == persona &&
      other.starters == starters &&
      other.skills == skills &&
      other.routines == routines &&
      other.tools == tools &&
      other.rules == rules &&
      other.knowledge == knowledge;

    @override
    int get hashCode =>
        id.hashCode +
        name.hashCode +
        description.hashCode +
        icon.hashCode +
        mascot.hashCode +
        autonomy.hashCode +
        persona.hashCode +
        starters.hashCode +
        skills.hashCode +
        routines.hashCode +
        tools.hashCode +
        rules.hashCode +
        knowledge.hashCode;

  factory PackBotPreview.fromJson(Map<String, dynamic> json) => _$PackBotPreviewFromJson(json);

  Map<String, dynamic> toJson() => _$PackBotPreviewToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum PackBotPreviewAutonomyEnum {
@JsonValue(r'ask_always')
askAlways(r'ask_always'),
@JsonValue(r'ask_risky')
askRisky(r'ask_risky');

const PackBotPreviewAutonomyEnum(this.value);

final String value;

@override
String toString() => value;
}


