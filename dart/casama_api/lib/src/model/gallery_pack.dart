//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/template_author.dart';
import 'package:casama_api/src/model/gallery_pack_contents.dart';
import 'package:casama_api/src/model/gallery_pack_set_items_inner.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'gallery_pack.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class GalleryPack {
  /// Returns a new [GalleryPack] instance.
  GalleryPack({

    required  this.kind,

    required  this.id,

    required  this.name,

    required  this.summary,

    required  this.icon,

    required  this.author,

    required  this.featured,

    required  this.reviewed,

    required  this.url,

    required  this.commit,

    required  this.contents,

    required  this.setItems,

    required  this.tags,
  });

  @JsonKey(
    
    name: r'kind',
    required: true,
    includeIfNull: false,
  )


  final GalleryPackKindEnum kind;



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
    
    name: r'summary',
    required: true,
    includeIfNull: false,
  )


  final String summary;



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


  final TemplateAuthor author;



  @JsonKey(
    
    name: r'featured',
    required: true,
    includeIfNull: false,
  )


  final bool featured;



  @JsonKey(
    
    name: r'reviewed',
    required: true,
    includeIfNull: false,
  )


  final bool reviewed;



  @JsonKey(
    
    name: r'url',
    required: true,
    includeIfNull: true,
  )


  final String? url;



  @JsonKey(
    
    name: r'commit',
    required: true,
    includeIfNull: true,
  )


  final String? commit;



  @JsonKey(
    
    name: r'contents',
    required: true,
    includeIfNull: true,
  )


  final GalleryPackContents? contents;



  @JsonKey(
    
    name: r'set_items',
    required: true,
    includeIfNull: true,
  )


  final List<GalleryPackSetItemsInner>? setItems;



  @JsonKey(
    
    name: r'tags',
    required: true,
    includeIfNull: false,
  )


  final List<String> tags;





    @override
    bool operator ==(Object other) => identical(this, other) || other is GalleryPack &&
      other.kind == kind &&
      other.id == id &&
      other.name == name &&
      other.summary == summary &&
      other.icon == icon &&
      other.author == author &&
      other.featured == featured &&
      other.reviewed == reviewed &&
      other.url == url &&
      other.commit == commit &&
      other.contents == contents &&
      other.setItems == setItems &&
      other.tags == tags;

    @override
    int get hashCode =>
        kind.hashCode +
        id.hashCode +
        name.hashCode +
        summary.hashCode +
        icon.hashCode +
        author.hashCode +
        featured.hashCode +
        reviewed.hashCode +
        (url == null ? 0 : url.hashCode) +
        (commit == null ? 0 : commit.hashCode) +
        (contents == null ? 0 : contents.hashCode) +
        (setItems == null ? 0 : setItems.hashCode) +
        tags.hashCode;

  factory GalleryPack.fromJson(Map<String, dynamic> json) => _$GalleryPackFromJson(json);

  Map<String, dynamic> toJson() => _$GalleryPackToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum GalleryPackKindEnum {
@JsonValue(r'set')
set_(r'set'),
@JsonValue(r'pack')
pack(r'pack');

const GalleryPackKindEnum(this.value);

final String value;

@override
String toString() => value;
}


