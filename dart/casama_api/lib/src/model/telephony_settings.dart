//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'telephony_settings.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class TelephonySettings {
  /// Returns a new [TelephonySettings] instance.
  TelephonySettings({

    required  this.connected,

    required  this.accountSid,

    required  this.fromNumber,

    required  this.allowPersonalNumbers,

    required  this.dailyCap,
  });

  @JsonKey(
    
    name: r'connected',
    required: true,
    includeIfNull: false,
  )


  final bool connected;



  @JsonKey(
    
    name: r'account_sid',
    required: true,
    includeIfNull: true,
  )


  final String? accountSid;



  @JsonKey(
    
    name: r'from_number',
    required: true,
    includeIfNull: true,
  )


  final String? fromNumber;



  @JsonKey(
    
    name: r'allow_personal_numbers',
    required: true,
    includeIfNull: false,
  )


  final bool allowPersonalNumbers;



  @JsonKey(
    
    name: r'daily_cap',
    required: true,
    includeIfNull: false,
  )


  final int dailyCap;





    @override
    bool operator ==(Object other) => identical(this, other) || other is TelephonySettings &&
      other.connected == connected &&
      other.accountSid == accountSid &&
      other.fromNumber == fromNumber &&
      other.allowPersonalNumbers == allowPersonalNumbers &&
      other.dailyCap == dailyCap;

    @override
    int get hashCode =>
        connected.hashCode +
        (accountSid == null ? 0 : accountSid.hashCode) +
        (fromNumber == null ? 0 : fromNumber.hashCode) +
        allowPersonalNumbers.hashCode +
        dailyCap.hashCode;

  factory TelephonySettings.fromJson(Map<String, dynamic> json) => _$TelephonySettingsFromJson(json);

  Map<String, dynamic> toJson() => _$TelephonySettingsToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

