//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:kasama_api/src/model/org_role.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'membership.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Membership {
  /// Returns a new [Membership] instance.
  Membership({

    required  this.id,

    required  this.orgId,

    required  this.userId,

    required  this.role,

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
    
    name: r'role',
    required: true,
    includeIfNull: false,
  )


  final OrgRole role;



  @JsonKey(
    
    name: r'created_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime createdAt;





    @override
    bool operator ==(Object other) => identical(this, other) || other is Membership &&
      other.id == id &&
      other.orgId == orgId &&
      other.userId == userId &&
      other.role == role &&
      other.createdAt == createdAt;

    @override
    int get hashCode =>
        id.hashCode +
        orgId.hashCode +
        userId.hashCode +
        role.hashCode +
        createdAt.hashCode;

  factory Membership.fromJson(Map<String, dynamic> json) => _$MembershipFromJson(json);

  Map<String, dynamic> toJson() => _$MembershipToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

