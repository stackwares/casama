//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'pending_invite.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PendingInvite {
  /// Returns a new [PendingInvite] instance.
  PendingInvite({

    required  this.id,

    required  this.email,

    required  this.role,

    required  this.expiresAt,

    required  this.createdAt,
  });

  @JsonKey(
    
    name: r'id',
    required: true,
    includeIfNull: false,
  )


  final String id;



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


  final PendingInviteRoleEnum role;



  @JsonKey(
    
    name: r'expires_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime expiresAt;



  @JsonKey(
    
    name: r'created_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime createdAt;





    @override
    bool operator ==(Object other) => identical(this, other) || other is PendingInvite &&
      other.id == id &&
      other.email == email &&
      other.role == role &&
      other.expiresAt == expiresAt &&
      other.createdAt == createdAt;

    @override
    int get hashCode =>
        id.hashCode +
        email.hashCode +
        role.hashCode +
        expiresAt.hashCode +
        createdAt.hashCode;

  factory PendingInvite.fromJson(Map<String, dynamic> json) => _$PendingInviteFromJson(json);

  Map<String, dynamic> toJson() => _$PendingInviteToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum PendingInviteRoleEnum {
@JsonValue(r'owner')
owner(r'owner'),
@JsonValue(r'admin')
admin(r'admin'),
@JsonValue(r'member')
member(r'member');

const PendingInviteRoleEnum(this.value);

final String value;

@override
String toString() => value;
}


