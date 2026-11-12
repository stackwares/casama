//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'workspace_member.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class WorkspaceMember {
  /// Returns a new [WorkspaceMember] instance.
  WorkspaceMember({

    required  this.userId,

    required  this.email,

    required  this.role,

     this.name,

     this.pronouns,

     this.photoId,
  });

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
    
    name: r'role',
    required: true,
    includeIfNull: false,
  )


  final WorkspaceMemberRoleEnum role;



  @JsonKey(
    
    name: r'name',
    required: false,
    includeIfNull: false,
  )


  final String? name;



  @JsonKey(
    
    name: r'pronouns',
    required: false,
    includeIfNull: false,
  )


  final String? pronouns;



  @JsonKey(
    
    name: r'photo_id',
    required: false,
    includeIfNull: false,
  )


  final String? photoId;





    @override
    bool operator ==(Object other) => identical(this, other) || other is WorkspaceMember &&
      other.userId == userId &&
      other.email == email &&
      other.role == role &&
      other.name == name &&
      other.pronouns == pronouns &&
      other.photoId == photoId;

    @override
    int get hashCode =>
        userId.hashCode +
        (email == null ? 0 : email.hashCode) +
        role.hashCode +
        (name == null ? 0 : name.hashCode) +
        (pronouns == null ? 0 : pronouns.hashCode) +
        (photoId == null ? 0 : photoId.hashCode);

  factory WorkspaceMember.fromJson(Map<String, dynamic> json) => _$WorkspaceMemberFromJson(json);

  Map<String, dynamic> toJson() => _$WorkspaceMemberToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum WorkspaceMemberRoleEnum {
@JsonValue(r'owner')
owner(r'owner'),
@JsonValue(r'admin')
admin(r'admin'),
@JsonValue(r'member')
member(r'member');

const WorkspaceMemberRoleEnum(this.value);

final String value;

@override
String toString() => value;
}


