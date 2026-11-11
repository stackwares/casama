//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'created_invite_link.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CreatedInviteLink {
  /// Returns a new [CreatedInviteLink] instance.
  CreatedInviteLink({

    required  this.id,

    required  this.orgId,

    required  this.role,

    required  this.tokenHint,

    required  this.expiresAt,

    required  this.maxUses,

    required  this.uses,

    required  this.revokedAt,

    required  this.createdAt,

     this.kind,

     this.requiresApproval,

     this.isDefault,

    required  this.token,

    required  this.url,
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


  final CreatedInviteLinkRoleEnum role;



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



  @JsonKey(
    
    name: r'kind',
    required: false,
    includeIfNull: false,
  )


  final CreatedInviteLinkKindEnum? kind;



  @JsonKey(
    
    name: r'requires_approval',
    required: false,
    includeIfNull: false,
  )


  final bool? requiresApproval;



  @JsonKey(
    
    name: r'is_default',
    required: false,
    includeIfNull: false,
  )


  final bool? isDefault;



      /// Shown once
  @JsonKey(
    
    name: r'token',
    required: true,
    includeIfNull: false,
  )


  final String token;



      /// The link to share (the app's /join/<token>)
  @JsonKey(
    
    name: r'url',
    required: true,
    includeIfNull: false,
  )


  final String url;





    @override
    bool operator ==(Object other) => identical(this, other) || other is CreatedInviteLink &&
      other.id == id &&
      other.orgId == orgId &&
      other.role == role &&
      other.tokenHint == tokenHint &&
      other.expiresAt == expiresAt &&
      other.maxUses == maxUses &&
      other.uses == uses &&
      other.revokedAt == revokedAt &&
      other.createdAt == createdAt &&
      other.kind == kind &&
      other.requiresApproval == requiresApproval &&
      other.isDefault == isDefault &&
      other.token == token &&
      other.url == url;

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
        createdAt.hashCode +
        kind.hashCode +
        requiresApproval.hashCode +
        isDefault.hashCode +
        token.hashCode +
        url.hashCode;

  factory CreatedInviteLink.fromJson(Map<String, dynamic> json) => _$CreatedInviteLinkFromJson(json);

  Map<String, dynamic> toJson() => _$CreatedInviteLinkToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum CreatedInviteLinkRoleEnum {
@JsonValue(r'admin')
admin(r'admin'),
@JsonValue(r'member')
member(r'member');

const CreatedInviteLinkRoleEnum(this.value);

final String value;

@override
String toString() => value;
}



enum CreatedInviteLinkKindEnum {
@JsonValue(r'link')
link(r'link'),
@JsonValue(r'code')
code(r'code');

const CreatedInviteLinkKindEnum(this.value);

final String value;

@override
String toString() => value;
}


