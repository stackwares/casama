//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/invite_preview_workspace.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'invite_preview.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class InvitePreview {
  /// Returns a new [InvitePreview] instance.
  InvitePreview({

    required  this.kind,

    required  this.workspace,

    required  this.role,

    required  this.inviterName,

    required  this.requiresApproval,

    required  this.emailHint,

    required  this.alreadyMember,
  });

  @JsonKey(
    
    name: r'kind',
    required: true,
    includeIfNull: false,
  )


  final InvitePreviewKindEnum kind;



  @JsonKey(
    
    name: r'workspace',
    required: true,
    includeIfNull: false,
  )


  final InvitePreviewWorkspace workspace;



  @JsonKey(
    
    name: r'role',
    required: true,
    includeIfNull: false,
  )


  final InvitePreviewRoleEnum role;



  @JsonKey(
    
    name: r'inviter_name',
    required: true,
    includeIfNull: true,
  )


  final String? inviterName;



  @JsonKey(
    
    name: r'requires_approval',
    required: true,
    includeIfNull: false,
  )


  final bool requiresApproval;



  @JsonKey(
    
    name: r'email_hint',
    required: true,
    includeIfNull: true,
  )


  final String? emailHint;



  @JsonKey(
    
    name: r'already_member',
    required: true,
    includeIfNull: true,
  )


  final bool? alreadyMember;





    @override
    bool operator ==(Object other) => identical(this, other) || other is InvitePreview &&
      other.kind == kind &&
      other.workspace == workspace &&
      other.role == role &&
      other.inviterName == inviterName &&
      other.requiresApproval == requiresApproval &&
      other.emailHint == emailHint &&
      other.alreadyMember == alreadyMember;

    @override
    int get hashCode =>
        kind.hashCode +
        workspace.hashCode +
        role.hashCode +
        (inviterName == null ? 0 : inviterName.hashCode) +
        requiresApproval.hashCode +
        (emailHint == null ? 0 : emailHint.hashCode) +
        (alreadyMember == null ? 0 : alreadyMember.hashCode);

  factory InvitePreview.fromJson(Map<String, dynamic> json) => _$InvitePreviewFromJson(json);

  Map<String, dynamic> toJson() => _$InvitePreviewToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum InvitePreviewKindEnum {
@JsonValue(r'link')
link(r'link'),
@JsonValue(r'code')
code(r'code'),
@JsonValue(r'email')
email(r'email');

const InvitePreviewKindEnum(this.value);

final String value;

@override
String toString() => value;
}



enum InvitePreviewRoleEnum {
@JsonValue(r'owner')
owner(r'owner'),
@JsonValue(r'admin')
admin(r'admin'),
@JsonValue(r'member')
member(r'member');

const InvitePreviewRoleEnum(this.value);

final String value;

@override
String toString() => value;
}


