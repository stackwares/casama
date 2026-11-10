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





    @override
    bool operator ==(Object other) => identical(this, other) || other is WorkspaceMember &&
      other.userId == userId &&
      other.email == email &&
      other.role == role;

    @override
    int get hashCode =>
        userId.hashCode +
        (email == null ? 0 : email.hashCode) +
        role.hashCode;

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


