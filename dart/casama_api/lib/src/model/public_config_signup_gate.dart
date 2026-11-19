//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'public_config_signup_gate.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PublicConfigSignupGate {
  /// Returns a new [PublicConfigSignupGate] instance.
  PublicConfigSignupGate({

    required  this.mode,

    required  this.waitlistUrl,
  });

  @JsonKey(
    
    name: r'mode',
    required: true,
    includeIfNull: false,
  )


  final String mode;



  @JsonKey(
    
    name: r'waitlist_url',
    required: true,
    includeIfNull: false,
  )


  final String waitlistUrl;





    @override
    bool operator ==(Object other) => identical(this, other) || other is PublicConfigSignupGate &&
      other.mode == mode &&
      other.waitlistUrl == waitlistUrl;

    @override
    int get hashCode =>
        mode.hashCode +
        waitlistUrl.hashCode;

  factory PublicConfigSignupGate.fromJson(Map<String, dynamic> json) => _$PublicConfigSignupGateFromJson(json);

  Map<String, dynamic> toJson() => _$PublicConfigSignupGateToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

