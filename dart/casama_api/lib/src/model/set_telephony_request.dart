//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'set_telephony_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SetTelephonyRequest {
  /// Returns a new [SetTelephonyRequest] instance.
  SetTelephonyRequest({

    required  this.accountSid,

     this.authToken,

    required  this.fromNumber,

     this.allowPersonalNumbers,

     this.dailyCap,
  });

  @JsonKey(
    
    name: r'account_sid',
    required: true,
    includeIfNull: false,
  )


  final String accountSid;



  @JsonKey(
    
    name: r'auth_token',
    required: false,
    includeIfNull: false,
  )


  final String? authToken;



  @JsonKey(
    
    name: r'from_number',
    required: true,
    includeIfNull: false,
  )


  final String fromNumber;



  @JsonKey(
    
    name: r'allow_personal_numbers',
    required: false,
    includeIfNull: false,
  )


  final bool? allowPersonalNumbers;



          // minimum: 0
          // maximum: 500
  @JsonKey(
    
    name: r'daily_cap',
    required: false,
    includeIfNull: false,
  )


  final int? dailyCap;





    @override
    bool operator ==(Object other) => identical(this, other) || other is SetTelephonyRequest &&
      other.accountSid == accountSid &&
      other.authToken == authToken &&
      other.fromNumber == fromNumber &&
      other.allowPersonalNumbers == allowPersonalNumbers &&
      other.dailyCap == dailyCap;

    @override
    int get hashCode =>
        accountSid.hashCode +
        authToken.hashCode +
        fromNumber.hashCode +
        allowPersonalNumbers.hashCode +
        dailyCap.hashCode;

  factory SetTelephonyRequest.fromJson(Map<String, dynamic> json) => _$SetTelephonyRequestFromJson(json);

  Map<String, dynamic> toJson() => _$SetTelephonyRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

