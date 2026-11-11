//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/gallery_author.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'gallery_detail.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class GalleryDetail {
  /// Returns a new [GalleryDetail] instance.
  GalleryDetail({

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

    required  this.document,

    required  this.files,

    required  this.skillMd,
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


  final GalleryDetailTypeEnum type;



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



  @JsonKey(
    
    name: r'document',
    required: true,
    includeIfNull: true,
  )


  final Map<String, Object?>? document;



  @JsonKey(
    
    name: r'files',
    required: true,
    includeIfNull: false,
  )


  final List<String> files;



  @JsonKey(
    
    name: r'skill_md',
    required: true,
    includeIfNull: true,
  )


  final String? skillMd;





    @override
    bool operator ==(Object other) => identical(this, other) || other is GalleryDetail &&
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
      other.document == document &&
      other.files == files &&
      other.skillMd == skillMd;

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
        (document == null ? 0 : document.hashCode) +
        files.hashCode +
        (skillMd == null ? 0 : skillMd.hashCode);

  factory GalleryDetail.fromJson(Map<String, dynamic> json) => _$GalleryDetailFromJson(json);

  Map<String, dynamic> toJson() => _$GalleryDetailToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum GalleryDetailTypeEnum {
@JsonValue(r'theme')
theme(r'theme'),
@JsonValue(r'scheme')
scheme(r'scheme'),
@JsonValue(r'wallpaper')
wallpaper(r'wallpaper'),
@JsonValue(r'skill')
skill(r'skill');

const GalleryDetailTypeEnum(this.value);

final String value;

@override
String toString() => value;
}


