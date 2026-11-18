//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'uploaded_media.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class UploadedMedia {
  /// Returns a new [UploadedMedia] instance.
  UploadedMedia({

    required  this.id,

    required  this.path,

    required  this.name,

    required  this.mimeType,

    required  this.size,

    required  this.creationId,
  });

  @JsonKey(
    
    name: r'id',
    required: true,
    includeIfNull: false,
  )


  final String id;



      /// Put this in a message attachment's path: media:<id>. No computer is needed
  @JsonKey(
    
    name: r'path',
    required: true,
    includeIfNull: false,
  )


  final String path;



  @JsonKey(
    
    name: r'name',
    required: true,
    includeIfNull: false,
  )


  final String name;



  @JsonKey(
    
    name: r'mime_type',
    required: true,
    includeIfNull: false,
  )


  final String mimeType;



  @JsonKey(
    
    name: r'size',
    required: true,
    includeIfNull: false,
  )


  final int size;



      /// The Library item, when saved to the Library
  @JsonKey(
    
    name: r'creation_id',
    required: true,
    includeIfNull: true,
  )


  final String? creationId;





    @override
    bool operator ==(Object other) => identical(this, other) || other is UploadedMedia &&
      other.id == id &&
      other.path == path &&
      other.name == name &&
      other.mimeType == mimeType &&
      other.size == size &&
      other.creationId == creationId;

    @override
    int get hashCode =>
        id.hashCode +
        path.hashCode +
        name.hashCode +
        mimeType.hashCode +
        size.hashCode +
        (creationId == null ? 0 : creationId.hashCode);

  factory UploadedMedia.fromJson(Map<String, dynamic> json) => _$UploadedMediaFromJson(json);

  Map<String, dynamic> toJson() => _$UploadedMediaToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

