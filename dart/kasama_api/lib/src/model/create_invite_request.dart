//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:kasama_api/src/model/invite_role.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'create_invite_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CreateInviteRequest {
  /// Returns a new [CreateInviteRequest] instance.
  CreateInviteRequest({

    required  this.email,

     this.role,
  });

  @JsonKey(
    
    name: r'email',
    required: true,
    includeIfNull: false,
  )


  final String email;



  @JsonKey(
    
    name: r'role',
    required: false,
    includeIfNull: false,
  )


  final InviteRole? role;





    @override
    bool operator ==(Object other) => identical(this, other) || other is CreateInviteRequest &&
      other.email == email &&
      other.role == role;

    @override
    int get hashCode =>
        email.hashCode +
        role.hashCode;

  factory CreateInviteRequest.fromJson(Map<String, dynamic> json) => _$CreateInviteRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CreateInviteRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

