//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'set_signup_gate_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SetSignupGateRequest {
  /// Returns a new [SetSignupGateRequest] instance.
  SetSignupGateRequest({

     this.mode,

     this.opensAt,

     this.invitesPerPerson,

     this.dailyAdmit,

     this.dailyEmailsMax,
  });

  @JsonKey(
    
    name: r'mode',
    required: false,
    includeIfNull: false,
  )


  final SetSignupGateRequestModeEnum? mode;



  @JsonKey(
    
    name: r'opens_at',
    required: false,
    includeIfNull: false,
  )


  final DateTime? opensAt;



          // minimum: 0
          // maximum: 100
  @JsonKey(
    
    name: r'invites_per_person',
    required: false,
    includeIfNull: false,
  )


  final int? invitesPerPerson;



          // minimum: 0
          // maximum: 10000
  @JsonKey(
    
    name: r'daily_admit',
    required: false,
    includeIfNull: false,
  )


  final int? dailyAdmit;



          // minimum: 0
          // maximum: 100000
  @JsonKey(
    
    name: r'daily_emails_max',
    required: false,
    includeIfNull: false,
  )


  final int? dailyEmailsMax;





    @override
    bool operator ==(Object other) => identical(this, other) || other is SetSignupGateRequest &&
      other.mode == mode &&
      other.opensAt == opensAt &&
      other.invitesPerPerson == invitesPerPerson &&
      other.dailyAdmit == dailyAdmit &&
      other.dailyEmailsMax == dailyEmailsMax;

    @override
    int get hashCode =>
        mode.hashCode +
        (opensAt == null ? 0 : opensAt.hashCode) +
        invitesPerPerson.hashCode +
        dailyAdmit.hashCode +
        dailyEmailsMax.hashCode;

  factory SetSignupGateRequest.fromJson(Map<String, dynamic> json) => _$SetSignupGateRequestFromJson(json);

  Map<String, dynamic> toJson() => _$SetSignupGateRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum SetSignupGateRequestModeEnum {
@JsonValue(r'open')
open(r'open'),
@JsonValue(r'invite_only')
inviteOnly(r'invite_only');

const SetSignupGateRequestModeEnum(this.value);

final String value;

@override
String toString() => value;
}


