//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/gallery_workspace_kind.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'gallery_update_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class GalleryUpdateRequest {
  /// Returns a new [GalleryUpdateRequest] instance.
  GalleryUpdateRequest({

    required  this.orgId,

    required  this.type,

    required  this.id,

     this.acceptAccess,
  });

  @JsonKey(
    
    name: r'org_id',
    required: true,
    includeIfNull: false,
  )


  final String orgId;



  @JsonKey(
    
    name: r'type',
    required: true,
    includeIfNull: false,
  )


  final GalleryWorkspaceKind type;



  @JsonKey(
    
    name: r'id',
    required: true,
    includeIfNull: false,
  )


  final String id;



      /// Apply even though the update can touch more or is breaking
  @JsonKey(
    
    name: r'accept_access',
    required: false,
    includeIfNull: false,
  )


  final bool? acceptAccess;





    @override
    bool operator ==(Object other) => identical(this, other) || other is GalleryUpdateRequest &&
      other.orgId == orgId &&
      other.type == type &&
      other.id == id &&
      other.acceptAccess == acceptAccess;

    @override
    int get hashCode =>
        orgId.hashCode +
        type.hashCode +
        id.hashCode +
        acceptAccess.hashCode;

  factory GalleryUpdateRequest.fromJson(Map<String, dynamic> json) => _$GalleryUpdateRequestFromJson(json);

  Map<String, dynamic> toJson() => _$GalleryUpdateRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

