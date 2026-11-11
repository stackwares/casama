//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'create_invites_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CreateInvitesRequest {
  /// Returns a new [CreateInvitesRequest] instance.
  CreateInvitesRequest({

    required  this.emails,

     this.role,
  });

  @JsonKey(
    
    name: r'emails',
    required: true,
    includeIfNull: false,
  )


  final List<String> emails;



  @JsonKey(
    
    name: r'role',
    required: false,
    includeIfNull: false,
  )


  final CreateInvitesRequestRoleEnum? role;





    @override
    bool operator ==(Object other) => identical(this, other) || other is CreateInvitesRequest &&
      other.emails == emails &&
      other.role == role;

    @override
    int get hashCode =>
        emails.hashCode +
        role.hashCode;

  factory CreateInvitesRequest.fromJson(Map<String, dynamic> json) => _$CreateInvitesRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CreateInvitesRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum CreateInvitesRequestRoleEnum {
@JsonValue(r'admin')
admin(r'admin'),
@JsonValue(r'member')
member(r'member');

const CreateInvitesRequestRoleEnum(this.value);

final String value;

@override
String toString() => value;
}


