//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'create_invite_code_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CreateInviteCodeRequest {
  /// Returns a new [CreateInviteCodeRequest] instance.
  CreateInviteCodeRequest({

     this.role,
  });

  @JsonKey(
    
    name: r'role',
    required: false,
    includeIfNull: false,
  )


  final CreateInviteCodeRequestRoleEnum? role;





    @override
    bool operator ==(Object other) => identical(this, other) || other is CreateInviteCodeRequest &&
      other.role == role;

    @override
    int get hashCode =>
        role.hashCode;

  factory CreateInviteCodeRequest.fromJson(Map<String, dynamic> json) => _$CreateInviteCodeRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CreateInviteCodeRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum CreateInviteCodeRequestRoleEnum {
@JsonValue(r'admin')
admin(r'admin'),
@JsonValue(r'member')
member(r'member');

const CreateInviteCodeRequestRoleEnum(this.value);

final String value;

@override
String toString() => value;
}


