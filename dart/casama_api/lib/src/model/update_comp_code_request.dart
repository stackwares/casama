//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'update_comp_code_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class UpdateCompCodeRequest {
  /// Returns a new [UpdateCompCodeRequest] instance.
  UpdateCompCodeRequest({

     this.disabled,

     this.redeemBy,

     this.maxRedemptions,
  });

  @JsonKey(
    
    name: r'disabled',
    required: false,
    includeIfNull: false,
  )


  final bool? disabled;



  @JsonKey(
    
    name: r'redeem_by',
    required: false,
    includeIfNull: false,
  )


  final DateTime? redeemBy;



          // minimum: 1
          // maximum: 10000
  @JsonKey(
    
    name: r'max_redemptions',
    required: false,
    includeIfNull: false,
  )


  final int? maxRedemptions;





    @override
    bool operator ==(Object other) => identical(this, other) || other is UpdateCompCodeRequest &&
      other.disabled == disabled &&
      other.redeemBy == redeemBy &&
      other.maxRedemptions == maxRedemptions;

    @override
    int get hashCode =>
        disabled.hashCode +
        (redeemBy == null ? 0 : redeemBy.hashCode) +
        maxRedemptions.hashCode;

  factory UpdateCompCodeRequest.fromJson(Map<String, dynamic> json) => _$UpdateCompCodeRequestFromJson(json);

  Map<String, dynamic> toJson() => _$UpdateCompCodeRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

