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





    @override
    bool operator ==(Object other) => identical(this, other) || other is GalleryAuthor &&
      other.name == name &&
      other.url == url;

    @override
    int get hashCode =>
        name.hashCode +
        url.hashCode;

  factory GalleryAuthor.fromJson(Map<String, dynamic> json) => _$GalleryAuthorFromJson(json);

  Map<String, dynamic> toJson() => _$GalleryAuthorToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

