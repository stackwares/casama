//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/gallery_kind.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'create_gallery_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CreateGalleryRequest {
  /// Returns a new [CreateGalleryRequest] instance.
  CreateGalleryRequest({

    required  this.kind,

    required  this.title,

     this.details,
  });

  @JsonKey(
    
    name: r'kind',
    required: true,
    includeIfNull: false,
  )


  final GalleryKind kind;



  @JsonKey(
    
    name: r'title',
    required: true,
    includeIfNull: false,
  )


  final String title;



  @JsonKey(
    
    name: r'details',
    required: false,
    includeIfNull: false,
  )


  final String? details;





    @override
    bool operator ==(Object other) => identical(this, other) || other is CreateGalleryRequest &&
      other.kind == kind &&
      other.title == title &&
      other.details == details;

    @override
    int get hashCode =>
        kind.hashCode +
        title.hashCode +
        details.hashCode;

  factory CreateGalleryRequest.fromJson(Map<String, dynamic> json) => _$CreateGalleryRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CreateGalleryRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

