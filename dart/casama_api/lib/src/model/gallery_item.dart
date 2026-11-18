//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/gallery_item_tested.dart';
import 'package:casama_api/src/model/gallery_access.dart';
import 'package:casama_api/src/model/gallery_ref.dart';
import 'package:casama_api/src/model/gallery_input.dart';
import 'package:casama_api/src/model/gallery_author.dart';
import 'package:casama_api/src/model/gallery_any_kind.dart';
import 'package:casama_api/src/model/gallery_stats.dart';
import 'package:casama_api/src/model/gallery_change.dart';
import 'package:casama_api/src/model/gallery_needs.dart';
import 'package:casama_api/src/model/template_season.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'gallery_item.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class GalleryItem {
  /// Returns a new [GalleryItem] instance.
  GalleryItem({

    required  this.id,

    required  this.type,

    required  this.name,

    required  this.author,

    required  this.license,

    required  this.tags,

    required  this.featured,

    required  this.retired,

    required  this.version,

    required  this.sha256,

     this.category,

     this.icon,

     this.description,

     this.requires,

     this.document,

    required  this.files,

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
  });

  @JsonKey(
    
    name: r'id',
    required: true,
    includeIfNull: false,
  )


  final String id;



  @JsonKey(
    
    name: r'type',
    required: true,
    includeIfNull: false,
  )


  final GalleryAnyKind type;



  @JsonKey(
    
    name: r'name',
    required: true,
    includeIfNull: false,
  )


  final String name;



  @JsonKey(
    
    name: r'author',
    required: true,
    includeIfNull: false,
  )


  final GalleryAuthor author;



  @JsonKey(
    
    name: r'license',
    required: true,
    includeIfNull: false,
  )


  final String license;



  @JsonKey(
    
    name: r'tags',
    required: true,
    includeIfNull: false,
  )


  final List<String> tags;



  @JsonKey(
    
    name: r'featured',
    required: true,
    includeIfNull: false,
  )


  final bool featured;



  @JsonKey(
    
    name: r'retired',
    required: true,
    includeIfNull: false,
  )


  final bool retired;



  @JsonKey(
    
    name: r'version',
    required: true,
    includeIfNull: false,
  )


  final int version;



  @JsonKey(
    
    name: r'sha256',
    required: true,
    includeIfNull: false,
  )


  final String sha256;



  @JsonKey(
    
    name: r'category',
    required: false,
    includeIfNull: false,
  )


  final String? category;



      /// A skill's Lucide icon name.
  @JsonKey(
    
    name: r'icon',
    required: false,
    includeIfNull: false,
  )


  final String? icon;



      /// A skill's one-line description.
  @JsonKey(
    
    name: r'description',
    required: false,
    includeIfNull: false,
  )


  final String? description;



      /// Features the look needs from the app (doodles, mesh, scheme-colors). Apps hide items that need something they can't draw.
  @JsonKey(
    
    name: r'requires',
    required: false,
    includeIfNull: false,
  )


  final List<String>? requires;



      /// A theme, scheme or wallpaper document, so a list can draw previews without fetching each item; an app, bot, routine or plugin entry; a set's set.json (items).
  @JsonKey(
    
    name: r'document',
    required: false,
    includeIfNull: false,
  )


  final Map<String, Object?>? document;



  @JsonKey(
    
    name: r'files',
    required: true,
    includeIfNull: false,
  )


  final List<String> files;



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





    @override
    bool operator ==(Object other) => identical(this, other) || other is GalleryItem &&
      other.id == id &&
      other.type == type &&
      other.name == name &&
      other.author == author &&
      other.license == license &&
      other.tags == tags &&
      other.featured == featured &&
      other.retired == retired &&
      other.version == version &&
      other.sha256 == sha256 &&
      other.category == category &&
      other.icon == icon &&
      other.description == description &&
      other.requires == requires &&
      other.document == document &&
      other.files == files &&
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
      other.template == template;

    @override
    int get hashCode =>
        id.hashCode +
        type.hashCode +
        name.hashCode +
        author.hashCode +
        license.hashCode +
        tags.hashCode +
        featured.hashCode +
        retired.hashCode +
        version.hashCode +
        sha256.hashCode +
        category.hashCode +
        icon.hashCode +
        description.hashCode +
        requires.hashCode +
        document.hashCode +
        files.hashCode +
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
        template.hashCode;

  factory GalleryItem.fromJson(Map<String, dynamic> json) => _$GalleryItemFromJson(json);

  Map<String, dynamic> toJson() => _$GalleryItemToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

