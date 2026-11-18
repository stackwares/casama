//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'redeem_sign_in_code_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class RedeemSignInCodeRequest {
  /// Returns a new [RedeemSignInCodeRequest] instance.
  RedeemSignInCodeRequest({

    required  this.code,

     this.deviceName,
  });

  @JsonKey(
    
    name: r'code',
    required: true,
    includeIfNull: false,
  )


  final String code;



  @JsonKey(
    
    name: r'device_name',
    required: false,
    includeIfNull: false,
  )


  final String? deviceName;





    @override
    bool operator ==(Object other) => identical(this, other) || other is RedeemSignInCodeRequest &&
      other.code == code &&
      other.deviceName == deviceName;

    @override
    int get hashCode =>
        code.hashCode +
        deviceName.hashCode;

  factory RedeemSignInCodeRequest.fromJson(Map<String, dynamic> json) => _$RedeemSignInCodeRequestFromJson(json);

  Map<String, dynamic> toJson() => _$RedeemSignInCodeRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

