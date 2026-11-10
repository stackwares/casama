//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:kasama_api/src/model/org_role.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'organization_with_role.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class OrganizationWithRole {
  /// Returns a new [OrganizationWithRole] instance.
  OrganizationWithRole({

    required  this.id,

    required  this.name,

    required  this.slug,

    required  this.plan,

    required  this.region,

    required  this.createdAt,

    required  this.role,

     this.requireMfa,

     this.suspended,
  });

  @JsonKey(
    
    name: r'id',
    required: true,
    includeIfNull: false,
  )


  final String id;



  @JsonKey(
    
    name: r'name',
    required: true,
    includeIfNull: false,
  )


  final String name;



  @JsonKey(
    
    name: r'slug',
    required: true,
    includeIfNull: false,
  )


  final String slug;



  @JsonKey(
    
    name: r'plan',
    required: true,
    includeIfNull: false,
  )


  final String plan;



  @JsonKey(
    
    name: r'region',
    required: true,
    includeIfNull: false,
  )


  final String region;



  @JsonKey(
    
    name: r'created_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime createdAt;



  @JsonKey(
    
    name: r'role',
    required: true,
    includeIfNull: false,
  )


  final OrgRole role;



      /// Owners and admins need two-step sign-in (an aal2 session) to use their powers
  @JsonKey(
    
    name: r'require_mfa',
    required: false,
    includeIfNull: false,
  )


  final bool? requireMfa;



      /// Suspended by the instance owner: bots don't run and computers don't start (D-094)
  @JsonKey(
    
    name: r'suspended',
    required: false,
    includeIfNull: false,
  )


  final bool? suspended;





    @override
    bool operator ==(Object other) => identical(this, other) || other is OrganizationWithRole &&
      other.id == id &&
      other.name == name &&
      other.slug == slug &&
      other.plan == plan &&
      other.region == region &&
      other.createdAt == createdAt &&
      other.role == role &&
      other.requireMfa == requireMfa &&
      other.suspended == suspended;

    @override
    int get hashCode =>
        id.hashCode +
        name.hashCode +
        slug.hashCode +
        plan.hashCode +
        region.hashCode +
        createdAt.hashCode +
        role.hashCode +
        requireMfa.hashCode +
        suspended.hashCode;

  factory OrganizationWithRole.fromJson(Map<String, dynamic> json) => _$OrganizationWithRoleFromJson(json);

  Map<String, dynamic> toJson() => _$OrganizationWithRoleToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

