//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/gallery_kind.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'gallery_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class GalleryRequest {
  /// Returns a new [GalleryRequest] instance.
  GalleryRequest({

    required  this.id,

    required  this.kind,

    required  this.title,

    required  this.details,

    required  this.status,

    required  this.doneItemKey,

    required  this.votes,

    required  this.voted,

    required  this.mine,

    required  this.createdAt,
  });

  @JsonKey(
    
    name: r'id',
    required: true,
    includeIfNull: false,
  )


  final String id;



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
    required: true,
    includeIfNull: false,
  )


  final String details;



  @JsonKey(
    
    name: r'status',
    required: true,
    includeIfNull: false,
  )


  final GalleryRequestStatusEnum status;



  @JsonKey(
    
    name: r'done_item_key',
    required: true,
    includeIfNull: true,
  )


  final String? doneItemKey;



  @JsonKey(
    
    name: r'votes',
    required: true,
    includeIfNull: false,
  )


  final int votes;



  @JsonKey(
    
    name: r'voted',
    required: true,
    includeIfNull: false,
  )


  final bool voted;



  @JsonKey(
    
    name: r'mine',
    required: true,
    includeIfNull: false,
  )


  final bool mine;



  @JsonKey(
    
    name: r'created_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime createdAt;





    @override
    bool operator ==(Object other) => identical(this, other) || other is GalleryRequest &&
      other.id == id &&
      other.kind == kind &&
      other.title == title &&
      other.details == details &&
      other.status == status &&
      other.doneItemKey == doneItemKey &&
      other.votes == votes &&
      other.voted == voted &&
      other.mine == mine &&
      other.createdAt == createdAt;

    @override
    int get hashCode =>
        id.hashCode +
        kind.hashCode +
        title.hashCode +
        details.hashCode +
        status.hashCode +
        (doneItemKey == null ? 0 : doneItemKey.hashCode) +
        votes.hashCode +
        voted.hashCode +
        mine.hashCode +
        createdAt.hashCode;

  factory GalleryRequest.fromJson(Map<String, dynamic> json) => _$GalleryRequestFromJson(json);

  Map<String, dynamic> toJson() => _$GalleryRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum GalleryRequestStatusEnum {
@JsonValue(r'open')
open(r'open'),
@JsonValue(r'planned')
planned(r'planned'),
@JsonValue(r'done')
done(r'done'),
@JsonValue(r'declined')
declined(r'declined');

const GalleryRequestStatusEnum(this.value);

final String value;

@override
String toString() => value;
}


