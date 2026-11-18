//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/gallery_workspace_kind.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'gallery_approval.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class GalleryApproval {
  /// Returns a new [GalleryApproval] instance.
  GalleryApproval({

    required  this.id,

    required  this.orgId,

    required  this.type,

     this.pack,

    required  this.itemId,

    required  this.name,

    required  this.requestedBy,

    required  this.requestedByName,

    required  this.reason,

    required  this.status,

    required  this.error,

    required  this.createdAt,

    required  this.decidedAt,
  });

  @JsonKey(
    
    name: r'id',
    required: true,
    includeIfNull: false,
  )


  final String id;



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



      /// A pack (shown as a plugin to older apps)
  @JsonKey(
    
    name: r'pack',
    required: false,
    includeIfNull: false,
  )


  final bool? pack;



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
    
    name: r'requested_by',
    required: true,
    includeIfNull: true,
  )


  final String? requestedBy;



  @JsonKey(
    
    name: r'requested_by_name',
    required: true,
    includeIfNull: true,
  )


  final String? requestedByName;



  @JsonKey(
    
    name: r'reason',
    required: true,
    includeIfNull: false,
  )


  final String reason;



  @JsonKey(
    
    name: r'status',
    required: true,
    includeIfNull: false,
  )


  final GalleryApprovalStatusEnum status;



  @JsonKey(
    
    name: r'error',
    required: true,
    includeIfNull: true,
  )


  final String? error;



  @JsonKey(
    
    name: r'created_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime createdAt;



  @JsonKey(
    
    name: r'decided_at',
    required: true,
    includeIfNull: true,
  )


  final DateTime? decidedAt;





    @override
    bool operator ==(Object other) => identical(this, other) || other is GalleryApproval &&
      other.id == id &&
      other.orgId == orgId &&
      other.type == type &&
      other.pack == pack &&
      other.itemId == itemId &&
      other.name == name &&
      other.requestedBy == requestedBy &&
      other.requestedByName == requestedByName &&
      other.reason == reason &&
      other.status == status &&
      other.error == error &&
      other.createdAt == createdAt &&
      other.decidedAt == decidedAt;

    @override
    int get hashCode =>
        id.hashCode +
        orgId.hashCode +
        type.hashCode +
        pack.hashCode +
        itemId.hashCode +
        name.hashCode +
        (requestedBy == null ? 0 : requestedBy.hashCode) +
        (requestedByName == null ? 0 : requestedByName.hashCode) +
        reason.hashCode +
        status.hashCode +
        (error == null ? 0 : error.hashCode) +
        createdAt.hashCode +
        (decidedAt == null ? 0 : decidedAt.hashCode);

  factory GalleryApproval.fromJson(Map<String, dynamic> json) => _$GalleryApprovalFromJson(json);

  Map<String, dynamic> toJson() => _$GalleryApprovalToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum GalleryApprovalStatusEnum {
@JsonValue(r'pending')
pending(r'pending'),
@JsonValue(r'approved')
approved(r'approved'),
@JsonValue(r'denied')
denied(r'denied'),
@JsonValue(r'failed')
failed(r'failed');

const GalleryApprovalStatusEnum(this.value);

final String value;

@override
String toString() => value;
}


