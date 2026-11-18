//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/gallery_author_item_stats.dart';
import 'package:casama_api/src/model/gallery_kind.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'gallery_author_item.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class GalleryAuthorItem {
  /// Returns a new [GalleryAuthorItem] instance.
  GalleryAuthorItem({

    required  this.type,

    required  this.id,

    required  this.name,

    required  this.version,

    required  this.stats,

    required  this.reportsOpen,
  });

  @JsonKey(
    
    name: r'type',
    required: true,
    includeIfNull: false,
  )


  final GalleryKind type;



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
    
    name: r'version',
    required: true,
    includeIfNull: true,
  )


  final int? version;



  @JsonKey(
    
    name: r'stats',
    required: true,
    includeIfNull: false,
  )


  final GalleryAuthorItemStats stats;



  @JsonKey(
    
    name: r'reports_open',
    required: true,
    includeIfNull: false,
  )


  final int reportsOpen;





    @override
    bool operator ==(Object other) => identical(this, other) || other is GalleryAuthorItem &&
      other.type == type &&
      other.id == id &&
      other.name == name &&
      other.version == version &&
      other.stats == stats &&
      other.reportsOpen == reportsOpen;

    @override
    int get hashCode =>
        type.hashCode +
        id.hashCode +
        name.hashCode +
        (version == null ? 0 : version.hashCode) +
        stats.hashCode +
        reportsOpen.hashCode;

  factory GalleryAuthorItem.fromJson(Map<String, dynamic> json) => _$GalleryAuthorItemFromJson(json);

  Map<String, dynamic> toJson() => _$GalleryAuthorItemToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

