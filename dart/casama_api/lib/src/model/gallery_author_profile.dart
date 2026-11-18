//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/gallery_ref.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'gallery_author_profile.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class GalleryAuthorProfile {
  /// Returns a new [GalleryAuthorProfile] instance.
  GalleryAuthorProfile({

    required  this.handle,

    required  this.name,

     this.url,

    required  this.items,
  });

  @JsonKey(
    
    name: r'handle',
    required: true,
    includeIfNull: false,
  )


  final String handle;



  @JsonKey(
    
    name: r'name',
    required: true,
    includeIfNull: false,
  )


  final String name;



  @JsonKey(
    
    name: r'url',
    required: false,
    includeIfNull: false,
  )


  final String? url;



  @JsonKey(
    
    name: r'items',
    required: true,
    includeIfNull: false,
  )


  final List<GalleryRef> items;





    @override
    bool operator ==(Object other) => identical(this, other) || other is GalleryAuthorProfile &&
      other.handle == handle &&
      other.name == name &&
      other.url == url &&
      other.items == items;

    @override
    int get hashCode =>
        handle.hashCode +
        name.hashCode +
        url.hashCode +
        items.hashCode;

  factory GalleryAuthorProfile.fromJson(Map<String, dynamic> json) => _$GalleryAuthorProfileFromJson(json);

  Map<String, dynamic> toJson() => _$GalleryAuthorProfileToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

