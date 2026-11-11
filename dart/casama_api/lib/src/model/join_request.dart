//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'join_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class JoinRequest {
  /// Returns a new [JoinRequest] instance.
  JoinRequest({

    required  this.id,

    required  this.orgId,

    required  this.userId,

    required  this.email,

    required  this.displayName,

    required  this.role,

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
    
    name: r'org_id',
    required: true,
    includeIfNull: false,
  )


  final String orgId;



  @JsonKey(
    
    name: r'user_id',
    required: true,
    includeIfNull: false,
  )


  final String userId;



  @JsonKey(
    
    name: r'email',
    required: true,
    includeIfNull: true,
  )


  final String? email;



  @JsonKey(
    
    name: r'display_name',
    required: true,
    includeIfNull: true,
  )


  final String? displayName;



  @JsonKey(
    
    name: r'role',
    required: true,
    includeIfNull: false,
  )


  final JoinRequestRoleEnum role;



  @JsonKey(
    
    name: r'status',
    required: true,
    includeIfNull: false,
  )


  final JoinRequestStatusEnum status;



  @JsonKey(
    
    name: r'created_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime createdAt;





    @override
    bool operator ==(Object other) => identical(this, other) || other is JoinRequest &&
      other.id == id &&
      other.orgId == orgId &&
      other.userId == userId &&
      other.email == email &&
      other.displayName == displayName &&
      other.role == role &&
      other.status == status &&
      other.createdAt == createdAt;

    @override
    int get hashCode =>
        id.hashCode +
        orgId.hashCode +
        userId.hashCode +
        (email == null ? 0 : email.hashCode) +
        (displayName == null ? 0 : displayName.hashCode) +
        role.hashCode +
        status.hashCode +
        createdAt.hashCode;

  factory JoinRequest.fromJson(Map<String, dynamic> json) => _$JoinRequestFromJson(json);

  Map<String, dynamic> toJson() => _$JoinRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum JoinRequestRoleEnum {
@JsonValue(r'admin')
admin(r'admin'),
@JsonValue(r'member')
member(r'member');

const JoinRequestRoleEnum(this.value);

final String value;

@override
String toString() => value;
}



enum JoinRequestStatusEnum {
@JsonValue(r'pending')
pending(r'pending'),
@JsonValue(r'approved')
approved(r'approved'),
@JsonValue(r'declined')
declined(r'declined');

const JoinRequestStatusEnum(this.value);

final String value;

@override
String toString() => value;
}


