//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:kasama_api/src/model/org_role.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'invite.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Invite {
  /// Returns a new [Invite] instance.
  Invite({

    required  this.id,

    required  this.orgId,

    required  this.email,

    required  this.role,

    required  this.expiresAt,

    required  this.emailSent,

     this.acceptToken,
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
    
    name: r'email',
    required: true,
    includeIfNull: false,
  )


  final String email;



  @JsonKey(
    
    name: r'role',
    required: true,
    includeIfNull: false,
  )


  final OrgRole role;



  @JsonKey(
    
    name: r'expires_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime expiresAt;



  @JsonKey(
    
    name: r'email_sent',
    required: true,
    includeIfNull: false,
  )


  final bool emailSent;



      /// Returned only when no email provider is configured, so the inviter can share it directly
  @JsonKey(
    
    name: r'accept_token',
    required: false,
    includeIfNull: false,
  )


  final String? acceptToken;





    @override
    bool operator ==(Object other) => identical(this, other) || other is Invite &&
      other.id == id &&
      other.orgId == orgId &&
      other.email == email &&
      other.role == role &&
      other.expiresAt == expiresAt &&
      other.emailSent == emailSent &&
      other.acceptToken == acceptToken;

    @override
    int get hashCode =>
        id.hashCode +
        orgId.hashCode +
        email.hashCode +
        role.hashCode +
        expiresAt.hashCode +
        emailSent.hashCode +
        acceptToken.hashCode;

  factory Invite.fromJson(Map<String, dynamic> json) => _$InviteFromJson(json);

  Map<String, dynamic> toJson() => _$InviteToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

