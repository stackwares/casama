//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:kasama_api/src/model/organization_with_role.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'me.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Me {
  /// Returns a new [Me] instance.
  Me({

    required  this.userId,

    required  this.email,

    required  this.displayName,

    required  this.locale,

    required  this.timezone,

    required  this.organizations,
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
    
    name: r'display_name',
    required: true,
    includeIfNull: true,
  )


  final String? displayName;



  @JsonKey(
    
    name: r'locale',
    required: true,
    includeIfNull: false,
  )


  final String locale;



  @JsonKey(
    
    name: r'timezone',
    required: true,
    includeIfNull: false,
  )


  final String timezone;



  @JsonKey(
    
    name: r'organizations',
    required: true,
    includeIfNull: false,
  )


  final List<OrganizationWithRole> organizations;





    @override
    bool operator ==(Object other) => identical(this, other) || other is Me &&
      other.userId == userId &&
      other.email == email &&
      other.displayName == displayName &&
      other.locale == locale &&
      other.timezone == timezone &&
      other.organizations == organizations;

    @override
    int get hashCode =>
        userId.hashCode +
        (email == null ? 0 : email.hashCode) +
        (displayName == null ? 0 : displayName.hashCode) +
        locale.hashCode +
        timezone.hashCode +
        organizations.hashCode;

  factory Me.fromJson(Map<String, dynamic> json) => _$MeFromJson(json);

  Map<String, dynamic> toJson() => _$MeToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

