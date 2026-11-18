//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/gallery_ref.dart';
import 'package:casama_api/src/model/gallery_submission_kind.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'create_gallery_submission.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CreateGallerySubmission {
  /// Returns a new [CreateGallerySubmission] instance.
  CreateGallerySubmission({

    required  this.type,

     this.id,

    required  this.item,

    required  this.files,

     this.remixOf,
  });

  @JsonKey(
    
    name: r'type',
    required: true,
    includeIfNull: false,
  )


  final GallerySubmissionKind type;



      /// Folder name; made from the name when left out
  @JsonKey(
    
    name: r'id',
    required: false,
    includeIfNull: false,
  )


  final String? id;



      /// item.json fields
  @JsonKey(
    
    name: r'item',
    required: true,
    includeIfNull: false,
  )


  final Map<String, Object?> item;



      /// The item's other files by name: theme.json, scheme.json, wallpaper.json, SKILL.md (plus .md references), routine.json, bot.json
  @JsonKey(
    
    name: r'files',
    required: true,
    includeIfNull: false,
  )


  final Map<String, String> files;



  @JsonKey(
    
    name: r'remix_of',
    required: false,
    includeIfNull: false,
  )


  final GalleryRef? remixOf;





    @override
    bool operator ==(Object other) => identical(this, other) || other is CreateGallerySubmission &&
      other.type == type &&
      other.id == id &&
      other.item == item &&
      other.files == files &&
      other.remixOf == remixOf;

    @override
    int get hashCode =>
        type.hashCode +
        id.hashCode +
        item.hashCode +
        files.hashCode +
        remixOf.hashCode;

  factory CreateGallerySubmission.fromJson(Map<String, dynamic> json) => _$CreateGallerySubmissionFromJson(json);

  Map<String, dynamic> toJson() => _$CreateGallerySubmissionToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

