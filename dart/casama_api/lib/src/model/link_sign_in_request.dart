//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'link_sign_in_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class LinkSignInRequest {
  /// Returns a new [LinkSignInRequest] instance.
  LinkSignInRequest({

    required  this.userCode,

    required  this.instanceName,

    required  this.platform,

    required  this.version,

    required  this.approved,

    required  this.expiresAt,
  });

      /// The code the server shows, like K7QM-2XFD
  @JsonKey(
    
    name: r'user_code',
    required: true,
    includeIfNull: false,
  )


  final String userCode;



  @JsonKey(
    
    name: r'instance_name',
    required: true,
    includeIfNull: false,
  )


  final String instanceName;



  @JsonKey(
    
    name: r'platform',
    required: true,
    includeIfNull: true,
  )


  final String? platform;



  @JsonKey(
    
    name: r'version',
    required: true,
    includeIfNull: true,
  )


  final String? version;



  @JsonKey(
    
    name: r'approved',
    required: true,
    includeIfNull: false,
  )


  final bool approved;



  @JsonKey(
    
    name: r'expires_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime expiresAt;





    @override
    bool operator ==(Object other) => identical(this, other) || other is LinkSignInRequest &&
      other.userCode == userCode &&
      other.instanceName == instanceName &&
      other.platform == platform &&
      other.version == version &&
      other.approved == approved &&
      other.expiresAt == expiresAt;

    @override
    int get hashCode =>
        userCode.hashCode +
        instanceName.hashCode +
        (platform == null ? 0 : platform.hashCode) +
        (version == null ? 0 : version.hashCode) +
        approved.hashCode +
        expiresAt.hashCode;

  factory LinkSignInRequest.fromJson(Map<String, dynamic> json) => _$LinkSignInRequestFromJson(json);

  Map<String, dynamic> toJson() => _$LinkSignInRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

