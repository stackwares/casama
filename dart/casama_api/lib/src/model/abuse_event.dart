//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'abuse_event.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AbuseEvent {
  /// Returns a new [AbuseEvent] instance.
  AbuseEvent({

    required  this.id,

    required  this.orgId,

    required  this.orgName,

    required  this.computerId,

    required  this.kind,

    required  this.action,

    required  this.detail,

    required  this.createdAt,
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
    includeIfNull: true,
  )


  final String? orgId;



  @JsonKey(
    
    name: r'org_name',
    required: true,
    includeIfNull: true,
  )


  final String? orgName;



  @JsonKey(
    
    name: r'computer_id',
    required: true,
    includeIfNull: true,
  )


  final String? computerId;



  @JsonKey(
    
    name: r'kind',
    required: true,
    includeIfNull: false,
  )


  final String kind;



  @JsonKey(
    
    name: r'action',
    required: true,
    includeIfNull: false,
  )


  final String action;



  @JsonKey(
    
    name: r'detail',
    required: true,
    includeIfNull: false,
  )


  final Map<String, Object?> detail;



  @JsonKey(
    
    name: r'created_at',
    required: true,
    includeIfNull: false,
  )


  final String createdAt;





    @override
    bool operator ==(Object other) => identical(this, other) || other is AbuseEvent &&
      other.id == id &&
      other.orgId == orgId &&
      other.orgName == orgName &&
      other.computerId == computerId &&
      other.kind == kind &&
      other.action == action &&
      other.detail == detail &&
      other.createdAt == createdAt;

    @override
    int get hashCode =>
        id.hashCode +
        (orgId == null ? 0 : orgId.hashCode) +
        (orgName == null ? 0 : orgName.hashCode) +
        (computerId == null ? 0 : computerId.hashCode) +
        kind.hashCode +
        action.hashCode +
        detail.hashCode +
        createdAt.hashCode;

  factory AbuseEvent.fromJson(Map<String, dynamic> json) => _$AbuseEventFromJson(json);

  Map<String, dynamic> toJson() => _$AbuseEventToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

