//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/gallery_ref.dart';
import 'package:casama_api/src/model/gallery_author.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'gallery_set.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class GallerySet {
  /// Returns a new [GallerySet] instance.
  GallerySet({

    required  this.id,

    required  this.name,

    required  this.description,

    required  this.icon,

    required  this.author,

    required  this.featured,

    required  this.items,

     this.source_,

     this.added,

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
    
    name: r'author',
    required: true,
    includeIfNull: false,
  )


  final GalleryAuthor author;



  @JsonKey(
    
    name: r'featured',
    required: true,
    includeIfNull: false,
  )


  final bool featured;



  @JsonKey(
    
    name: r'items',
    required: true,
    includeIfNull: false,
  )


  final List<GalleryRef> items;



  @JsonKey(
    
    name: r'source',
    required: false,
    includeIfNull: false,
  )


  final String? source_;



  @JsonKey(
    
    name: r'added',
    required: false,
    includeIfNull: false,
  )


  final String? added;



      /// Absolute URL of the set's painted cover picture (cover.webp), when it has one
  @JsonKey(
    
    name: r'cover',
    required: false,
    includeIfNull: false,
  )


  final String? cover;





    @override
    bool operator ==(Object other) => identical(this, other) || other is GallerySet &&
      other.id == id &&
      other.name == name &&
      other.description == description &&
      other.icon == icon &&
      other.author == author &&
      other.featured == featured &&
      other.items == items &&
      other.source_ == source_ &&
      other.added == added &&
      other.cover == cover;

    @override
    int get hashCode =>
        id.hashCode +
        name.hashCode +
        description.hashCode +
        icon.hashCode +
        author.hashCode +
        featured.hashCode +
        items.hashCode +
        source_.hashCode +
        added.hashCode +
        cover.hashCode;

  factory GallerySet.fromJson(Map<String, dynamic> json) => _$GallerySetFromJson(json);

  Map<String, dynamic> toJson() => _$GallerySetToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

