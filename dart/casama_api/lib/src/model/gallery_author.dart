//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'gallery_author.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class GalleryAuthor {
  /// Returns a new [GalleryAuthor] instance.
  GalleryAuthor({

    required  this.name,

     this.url,

     this.handle,
  });

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



      /// Stable author id for author pages (D-315)
  @JsonKey(
    
    name: r'handle',
    required: false,
    includeIfNull: false,
  )


  final String? handle;





    @override
    bool operator ==(Object other) => identical(this, other) || other is GalleryAuthor &&
      other.name == name &&
      other.url == url &&
      other.handle == handle;

    @override
    int get hashCode =>
        name.hashCode +
        url.hashCode +
        handle.hashCode;

  factory GalleryAuthor.fromJson(Map<String, dynamic> json) => _$GalleryAuthorFromJson(json);

  Map<String, dynamic> toJson() => _$GalleryAuthorToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

