//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/gallery_item_tested.dart';
import 'package:casama_api/src/model/gallery_access.dart';
import 'package:casama_api/src/model/gallery_ref.dart';
import 'package:casama_api/src/model/gallery_input.dart';
import 'package:casama_api/src/model/gallery_stats.dart';
import 'package:casama_api/src/model/content_author.dart';
import 'package:casama_api/src/model/gallery_change.dart';
import 'package:casama_api/src/model/gallery_needs.dart';
import 'package:casama_api/src/model/template_season.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'routine_idea.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class RoutineIdea {
  /// Returns a new [RoutineIdea] instance.
  RoutineIdea({

    required  this.id,

    required  this.name,

    required  this.description,

    required  this.category,

    required  this.icon,

    required  this.instructionsMd,

    required  this.scheduleCron,

    required  this.featured,

    required  this.author,

     this.added,

     this.updated,

     this.changelog,

     this.pick,

     this.examples,

     this.access,

     this.needs,

     this.inputs,

     this.remixOf,

     this.replacedBy,

     this.minApp,

     this.minServer,

     this.season,

     this.tested,

     this.source_,

     this.stats,

     this.template,

     this.version,

     this.tags,
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
    
    name: r'category',
    required: true,
    includeIfNull: false,
  )


  final RoutineIdeaCategoryEnum category;



      /// Lucide icon name, kebab-case
  @JsonKey(
    
    name: r'icon',
    required: true,
    includeIfNull: false,
  )


  final String icon;



  @JsonKey(
    
    name: r'instructions_md',
    required: true,
    includeIfNull: false,
  )


  final String instructionsMd;



  @JsonKey(
    
    name: r'schedule_cron',
    required: true,
    includeIfNull: false,
  )


  final String scheduleCron;



  @JsonKey(
    
    name: r'featured',
    required: true,
    includeIfNull: false,
  )


  final bool featured;



  @JsonKey(
    
    name: r'author',
    required: true,
    includeIfNull: false,
  )


  final ContentAuthor author;



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



  @JsonKey(
    
    name: r'changelog',
    required: false,
    includeIfNull: false,
  )


  final List<GalleryChange>? changelog;



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
    
    name: r'remix_of',
    required: false,
    includeIfNull: false,
  )


  final GalleryRef? remixOf;



  @JsonKey(
    
    name: r'replaced_by',
    required: false,
    includeIfNull: false,
  )


  final GalleryRef? replacedBy;



  @JsonKey(
    
    name: r'min_app',
    required: false,
    includeIfNull: false,
  )


  final String? minApp;



  @JsonKey(
    
    name: r'min_server',
    required: false,
    includeIfNull: false,
  )


  final String? minServer;



  @JsonKey(
    
    name: r'season',
    required: false,
    includeIfNull: false,
  )


  final TemplateSeason? season;



  @JsonKey(
    
    name: r'tested',
    required: false,
    includeIfNull: false,
  )


  final GalleryItemTested? tested;



      /// The extra catalog it came from (GALLERY_SOURCES); ids are source:id
  @JsonKey(
    
    name: r'source',
    required: false,
    includeIfNull: false,
  )


  final String? source_;



  @JsonKey(
    
    name: r'stats',
    required: false,
    includeIfNull: false,
  )


  final GalleryStats? stats;



      /// Routines and bots with install questions: the raw fields with {{key}} placeholders (document has the defaults filled)
  @JsonKey(
    
    name: r'template',
    required: false,
    includeIfNull: false,
  )


  final Map<String, Object?>? template;



  @JsonKey(
    
    name: r'version',
    required: false,
    includeIfNull: false,
  )


  final int? version;



  @JsonKey(
    
    name: r'tags',
    required: false,
    includeIfNull: false,
  )


  final List<String>? tags;





    @override
    bool operator ==(Object other) => identical(this, other) || other is RoutineIdea &&
      other.id == id &&
      other.name == name &&
      other.description == description &&
      other.category == category &&
      other.icon == icon &&
      other.instructionsMd == instructionsMd &&
      other.scheduleCron == scheduleCron &&
      other.featured == featured &&
      other.author == author &&
      other.added == added &&
      other.updated == updated &&
      other.changelog == changelog &&
      other.pick == pick &&
      other.examples == examples &&
      other.access == access &&
      other.needs == needs &&
      other.inputs == inputs &&
      other.remixOf == remixOf &&
      other.replacedBy == replacedBy &&
      other.minApp == minApp &&
      other.minServer == minServer &&
      other.season == season &&
      other.tested == tested &&
      other.source_ == source_ &&
      other.stats == stats &&
      other.template == template &&
      other.version == version &&
      other.tags == tags;

    @override
    int get hashCode =>
        id.hashCode +
        name.hashCode +
        description.hashCode +
        category.hashCode +
        icon.hashCode +
        instructionsMd.hashCode +
        scheduleCron.hashCode +
        featured.hashCode +
        author.hashCode +
        added.hashCode +
        updated.hashCode +
        changelog.hashCode +
        pick.hashCode +
        examples.hashCode +
        access.hashCode +
        needs.hashCode +
        inputs.hashCode +
        remixOf.hashCode +
        replacedBy.hashCode +
        minApp.hashCode +
        minServer.hashCode +
        season.hashCode +
        tested.hashCode +
        source_.hashCode +
        stats.hashCode +
        template.hashCode +
        version.hashCode +
        tags.hashCode;

  factory RoutineIdea.fromJson(Map<String, dynamic> json) => _$RoutineIdeaFromJson(json);

  Map<String, dynamic> toJson() => _$RoutineIdeaToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum RoutineIdeaCategoryEnum {
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

const RoutineIdeaCategoryEnum(this.value);

final String value;

@override
String toString() => value;
}


