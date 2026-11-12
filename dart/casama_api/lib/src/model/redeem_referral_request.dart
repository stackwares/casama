//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'redeem_referral_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class RedeemReferralRequest {
  /// Returns a new [RedeemReferralRequest] instance.
  RedeemReferralRequest({

    required  this.code,
  });

  @JsonKey(
    
    name: r'code',
    required: true,
    includeIfNull: false,
  )


  final String code;





    @override
    bool operator ==(Object other) => identical(this, other) || other is RedeemReferralRequest &&
      other.code == code;

    @override
    int get hashCode =>
        code.hashCode;

  factory RedeemReferralRequest.fromJson(Map<String, dynamic> json) => _$RedeemReferralRequestFromJson(json);

  Map<String, dynamic> toJson() => _$RedeemReferralRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

