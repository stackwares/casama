//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/gallery_submission_kind.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'gallery_submission.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class GallerySubmission {
  /// Returns a new [GallerySubmission] instance.
  GallerySubmission({

    required  this.id,

    required  this.type,

    required  this.itemId,

    required  this.name,

    required  this.prUrl,

    required  this.status,

    required  this.createdAt,
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


  final GallerySubmissionKind type;



  @JsonKey(
    
    name: r'item_id',
    required: true,
    includeIfNull: false,
  )


  final String itemId;



  @JsonKey(
    
    name: r'name',
    required: true,
    includeIfNull: false,
  )


  final String name;



  @JsonKey(
    
    name: r'pr_url',
    required: true,
    includeIfNull: true,
  )


  final String? prUrl;



  @JsonKey(
    
    name: r'status',
    required: true,
    includeIfNull: false,
  )


  final GallerySubmissionStatusEnum status;



  @JsonKey(
    
    name: r'created_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime createdAt;





    @override
    bool operator ==(Object other) => identical(this, other) || other is GallerySubmission &&
      other.id == id &&
      other.type == type &&
      other.itemId == itemId &&
      other.name == name &&
      other.prUrl == prUrl &&
      other.status == status &&
      other.createdAt == createdAt;

    @override
    int get hashCode =>
        id.hashCode +
        type.hashCode +
        itemId.hashCode +
        name.hashCode +
        (prUrl == null ? 0 : prUrl.hashCode) +
        status.hashCode +
        createdAt.hashCode;

  factory GallerySubmission.fromJson(Map<String, dynamic> json) => _$GallerySubmissionFromJson(json);

  Map<String, dynamic> toJson() => _$GallerySubmissionToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum GallerySubmissionStatusEnum {
@JsonValue(r'open')
open(r'open'),
@JsonValue(r'merged')
merged(r'merged'),
@JsonValue(r'closed')
closed(r'closed'),
@JsonValue(r'failed')
failed(r'failed');

const GallerySubmissionStatusEnum(this.value);

final String value;

@override
String toString() => value;
}


