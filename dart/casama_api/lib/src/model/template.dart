//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/gallery_access.dart';
import 'package:casama_api/src/model/template_routines_inner.dart';
import 'package:casama_api/src/model/gallery_input.dart';
import 'package:casama_api/src/model/template_author.dart';
import 'package:casama_api/src/model/gallery_stats.dart';
import 'package:casama_api/src/model/gallery_needs.dart';
import 'package:casama_api/src/model/template_season.dart';
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

     this.botName,

    required  this.description,

    required  this.autonomy,

    required  this.skills,

    required  this.routines,

     this.persona,

     this.category,

     this.icon,

     this.mascot,

     this.starters,

     this.author,

     this.added,

     this.updated,

     this.pick,

     this.examples,

     this.access,

     this.needs,

     this.inputs,

     this.minApp,

     this.season,

     this.source_,

     this.version,

     this.stats,

     this.cover,
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
    
    name: r'bot_name',
    required: false,
    includeIfNull: false,
  )


  final String? botName;



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



  @JsonKey(
    
    name: r'persona',
    required: false,
    includeIfNull: false,
  )


  final String? persona;



  @JsonKey(
    
    name: r'category',
    required: false,
    includeIfNull: false,
  )


  final TemplateCategoryEnum? category;



  @JsonKey(
    
    name: r'icon',
    required: false,
    includeIfNull: false,
  )


  final String? icon;



  @JsonKey(
    
    name: r'mascot',
    required: false,
    includeIfNull: false,
  )


  final String? mascot;



  @JsonKey(
    
    name: r'starters',
    required: false,
    includeIfNull: false,
  )


  final List<String>? starters;



  @JsonKey(
    
    name: r'author',
    required: false,
    includeIfNull: false,
  )


  final TemplateAuthor? author;



      /// YYYY-MM-DD the item was added
  @JsonKey(
    
    name: r'added',
    required: false,
    includeIfNull: false,
  )


  final String? added;



  @JsonKey(
    
    name: r'updated',
    required: false,
    includeIfNull: false,
  )


  final String? updated;



      /// Why a featured item is a pick
  @JsonKey(
    
    name: r'pick',
    required: false,
    includeIfNull: false,
  )


  final String? pick;



  @JsonKey(
    
    name: r'examples',
    required: false,
    includeIfNull: false,
  )


  final List<String>? examples;



  @JsonKey(
    
    name: r'access',
    required: false,
    includeIfNull: false,
  )


  final GalleryAccess? access;



  @JsonKey(
    
    name: r'needs',
    required: false,
    includeIfNull: false,
  )


  final GalleryNeeds? needs;



  @JsonKey(
    
    name: r'inputs',
    required: false,
    includeIfNull: false,
  )


  final List<GalleryInput>? inputs;



  @JsonKey(
    
    name: r'min_app',
    required: false,
    includeIfNull: false,
  )


  final String? minApp;



  @JsonKey(
    
    name: r'season',
    required: false,
    includeIfNull: false,
  )


  final TemplateSeason? season;



      /// The extra catalog it came from (GALLERY_SOURCES); ids are source:id
  @JsonKey(
    
    name: r'source',
    required: false,
    includeIfNull: false,
  )


  final String? source_;



  @JsonKey(
    
    name: r'version',
    required: false,
    includeIfNull: false,
  )


  final int? version;



  @JsonKey(
    
    name: r'stats',
    required: false,
    includeIfNull: false,
  )


  final GalleryStats? stats;



      /// Absolute URL of the item's painted cover picture (cover.webp), when it has one
  @JsonKey(
    
    name: r'cover',
    required: false,
    includeIfNull: false,
  )


  final String? cover;





    @override
    bool operator ==(Object other) => identical(this, other) || other is Template &&
      other.id == id &&
      other.name == name &&
      other.botName == botName &&
      other.description == description &&
      other.autonomy == autonomy &&
      other.skills == skills &&
      other.routines == routines &&
      other.persona == persona &&
      other.category == category &&
      other.icon == icon &&
      other.mascot == mascot &&
      other.starters == starters &&
      other.author == author &&
      other.added == added &&
      other.updated == updated &&
      other.pick == pick &&
      other.examples == examples &&
      other.access == access &&
      other.needs == needs &&
      other.inputs == inputs &&
      other.minApp == minApp &&
      other.season == season &&
      other.source_ == source_ &&
      other.version == version &&
      other.stats == stats &&
      other.cover == cover;

    @override
    int get hashCode =>
        id.hashCode +
        name.hashCode +
        botName.hashCode +
        description.hashCode +
        autonomy.hashCode +
        skills.hashCode +
        routines.hashCode +
        persona.hashCode +
        category.hashCode +
        icon.hashCode +
        mascot.hashCode +
        starters.hashCode +
        author.hashCode +
        added.hashCode +
        updated.hashCode +
        pick.hashCode +
        examples.hashCode +
        access.hashCode +
        needs.hashCode +
        inputs.hashCode +
        minApp.hashCode +
        season.hashCode +
        source_.hashCode +
        version.hashCode +
        stats.hashCode +
        cover.hashCode;

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



enum TemplateCategoryEnum {
@JsonValue(r'work')
work(r'work'),
@JsonValue(r'research')
research(r'research'),
@JsonValue(r'build')
build(r'build'),
@JsonValue(r'create')
create(r'create'),
@JsonValue(r'life')
life(r'life');

const TemplateCategoryEnum(this.value);

final String value;

@override
String toString() => value;
}


