//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'invite_link.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class InviteLink {
  /// Returns a new [InviteLink] instance.
  InviteLink({

    required  this.id,

    required  this.orgId,

    required  this.role,

    required  this.tokenHint,

    required  this.expiresAt,

    required  this.maxUses,

    required  this.uses,

    required  this.revokedAt,

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
    
    name: r'role',
    required: true,
    includeIfNull: false,
  )


  final InviteLinkRoleEnum role;



  @JsonKey(
    
    name: r'token_hint',
    required: true,
    includeIfNull: false,
  )


  final String tokenHint;



  @JsonKey(
    
    name: r'expires_at',
    required: true,
    includeIfNull: true,
  )


  final DateTime? expiresAt;



  @JsonKey(
    
    name: r'max_uses',
    required: true,
    includeIfNull: true,
  )


  final int? maxUses;



  @JsonKey(
    
    name: r'uses',
    required: true,
    includeIfNull: false,
  )


  final int uses;



  @JsonKey(
    
    name: r'revoked_at',
    required: true,
    includeIfNull: true,
  )


  final DateTime? revokedAt;



  @JsonKey(
    
    name: r'created_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime createdAt;





    @override
    bool operator ==(Object other) => identical(this, other) || other is InviteLink &&
      other.id == id &&
      other.orgId == orgId &&
      other.role == role &&
      other.tokenHint == tokenHint &&
      other.expiresAt == expiresAt &&
      other.maxUses == maxUses &&
      other.uses == uses &&
      other.revokedAt == revokedAt &&
      other.createdAt == createdAt;

    @override
    int get hashCode =>
        id.hashCode +
        orgId.hashCode +
        role.hashCode +
        tokenHint.hashCode +
        (expiresAt == null ? 0 : expiresAt.hashCode) +
        (maxUses == null ? 0 : maxUses.hashCode) +
        uses.hashCode +
        (revokedAt == null ? 0 : revokedAt.hashCode) +
        createdAt.hashCode;

  factory InviteLink.fromJson(Map<String, dynamic> json) => _$InviteLinkFromJson(json);

  Map<String, dynamic> toJson() => _$InviteLinkToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum InviteLinkRoleEnum {
@JsonValue(r'admin')
admin(r'admin'),
@JsonValue(r'member')
member(r'member');

const InviteLinkRoleEnum(this.value);

final String value;

@override
String toString() => value;
}


