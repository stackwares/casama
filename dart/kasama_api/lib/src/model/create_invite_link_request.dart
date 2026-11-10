//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'create_invite_link_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CreateInviteLinkRequest {
  /// Returns a new [CreateInviteLinkRequest] instance.
  CreateInviteLinkRequest({

     this.role,

     this.expiresInDays,

     this.maxUses,
  });

  @JsonKey(
    
    name: r'role',
    required: false,
    includeIfNull: false,
  )


  final CreateInviteLinkRequestRoleEnum? role;



          // minimum: 1
          // maximum: 365
  @JsonKey(
    
    name: r'expires_in_days',
    required: false,
    includeIfNull: false,
  )


  final int? expiresInDays;



          // minimum: 1
          // maximum: 10000
  @JsonKey(
    
    name: r'max_uses',
    required: false,
    includeIfNull: false,
  )


  final int? maxUses;





    @override
    bool operator ==(Object other) => identical(this, other) || other is CreateInviteLinkRequest &&
      other.role == role &&
      other.expiresInDays == expiresInDays &&
      other.maxUses == maxUses;

    @override
    int get hashCode =>
        role.hashCode +
        expiresInDays.hashCode +
        maxUses.hashCode;

  factory CreateInviteLinkRequest.fromJson(Map<String, dynamic> json) => _$CreateInviteLinkRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CreateInviteLinkRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum CreateInviteLinkRequestRoleEnum {
@JsonValue(r'admin')
admin(r'admin'),
@JsonValue(r'member')
member(r'member');

const CreateInviteLinkRequestRoleEnum(this.value);

final String value;

@override
String toString() => value;
}


