//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:kasama_api/src/model/template_routines_inner.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'template.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Template {
  /// Returns a new [Template] instance.
  Template({

    required  this.id,

    required  this.name,

    required  this.description,

    required  this.autonomy,

    required  this.skills,

    required  this.routines,
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
    
    name: r'autonomy',
    required: true,
    includeIfNull: false,
  )


  final TemplateAutonomyEnum autonomy;



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


  final List<TemplateRoutinesInner> routines;





    @override
    bool operator ==(Object other) => identical(this, other) || other is Template &&
      other.id == id &&
      other.name == name &&
      other.description == description &&
      other.autonomy == autonomy &&
      other.skills == skills &&
      other.routines == routines;

    @override
    int get hashCode =>
        id.hashCode +
        name.hashCode +
        description.hashCode +
        autonomy.hashCode +
        skills.hashCode +
        routines.hashCode;

  factory Template.fromJson(Map<String, dynamic> json) => _$TemplateFromJson(json);

  Map<String, dynamic> toJson() => _$TemplateToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum TemplateAutonomyEnum {
@JsonValue(r'ask_always')
askAlways(r'ask_always'),
@JsonValue(r'ask_risky')
askRisky(r'ask_risky'),
@JsonValue(r'autonomous')
autonomous(r'autonomous');

const TemplateAutonomyEnum(this.value);

final String value;

@override
String toString() => value;
}


