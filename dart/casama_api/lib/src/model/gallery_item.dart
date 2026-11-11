//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/gallery_author.dart';
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


  final GalleryItemTypeEnum type;



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



      /// A theme, scheme or wallpaper document, so a list can draw previews without fetching each item.
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
      other.files == files;

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
        files.hashCode;

  factory GalleryItem.fromJson(Map<String, dynamic> json) => _$GalleryItemFromJson(json);

  Map<String, dynamic> toJson() => _$GalleryItemToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum GalleryItemTypeEnum {
@JsonValue(r'theme')
theme(r'theme'),
@JsonValue(r'scheme')
scheme(r'scheme'),
@JsonValue(r'wallpaper')
wallpaper(r'wallpaper'),
@JsonValue(r'skill')
skill(r'skill');

const GalleryItemTypeEnum(this.value);

final String value;

@override
String toString() => value;
}


