//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'signup_gate.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SignupGate {
  /// Returns a new [SignupGate] instance.
  SignupGate({

    required  this.mode,

    required  this.opensAt,

    required  this.invitesPerPerson,

    required  this.dailyAdmit,

    required  this.dailyEmailsMax,

     this.batchHourUtc,
  });

  @JsonKey(
    
    name: r'mode',
    required: true,
    includeIfNull: false,
  )


  final SignupGateModeEnum mode;



  @JsonKey(
    
    name: r'opens_at',
    required: true,
    includeIfNull: true,
  )


  final DateTime? opensAt;



          // minimum: 0
          // maximum: 100
  @JsonKey(
    
    name: r'invites_per_person',
    required: true,
    includeIfNull: false,
  )


  final int invitesPerPerson;



          // minimum: 0
          // maximum: 10000
  @JsonKey(
    
    name: r'daily_admit',
    required: true,
    includeIfNull: false,
  )


  final int dailyAdmit;



          // minimum: 0
          // maximum: 100000
  @JsonKey(
    
    name: r'daily_emails_max',
    required: true,
    includeIfNull: false,
  )


  final int dailyEmailsMax;



          // minimum: 0
          // maximum: 23
  @JsonKey(
    
    name: r'batch_hour_utc',
    required: false,
    includeIfNull: false,
  )


  final int? batchHourUtc;





    @override
    bool operator ==(Object other) => identical(this, other) || other is SignupGate &&
      other.mode == mode &&
      other.opensAt == opensAt &&
      other.invitesPerPerson == invitesPerPerson &&
      other.dailyAdmit == dailyAdmit &&
      other.dailyEmailsMax == dailyEmailsMax &&
      other.batchHourUtc == batchHourUtc;

    @override
    int get hashCode =>
        mode.hashCode +
        (opensAt == null ? 0 : opensAt.hashCode) +
        invitesPerPerson.hashCode +
        dailyAdmit.hashCode +
        dailyEmailsMax.hashCode +
        batchHourUtc.hashCode;

  factory SignupGate.fromJson(Map<String, dynamic> json) => _$SignupGateFromJson(json);

  Map<String, dynamic> toJson() => _$SignupGateToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum SignupGateModeEnum {
@JsonValue(r'open')
open(r'open'),
@JsonValue(r'invite_only')
inviteOnly(r'invite_only');

const SignupGateModeEnum(this.value);

final String value;

@override
String toString() => value;
}


