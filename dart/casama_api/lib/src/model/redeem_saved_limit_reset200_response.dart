//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'redeem_saved_limit_reset200_response.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class RedeemSavedLimitReset200Response {
  /// Returns a new [RedeemSavedLimitReset200Response] instance.
  RedeemSavedLimitReset200Response({

    required  this.resetId,

    required  this.refilledUsd,
  });

  @JsonKey(
    
    name: r'reset_id',
    required: true,
    includeIfNull: false,
  )


  final String resetId;



  @JsonKey(
    
    name: r'refilled_usd',
    required: true,
    includeIfNull: false,
  )


  final num refilledUsd;





    @override
    bool operator ==(Object other) => identical(this, other) || other is RedeemSavedLimitReset200Response &&
      other.resetId == resetId &&
      other.refilledUsd == refilledUsd;

    @override
    int get hashCode =>
        resetId.hashCode +
        refilledUsd.hashCode;

  factory RedeemSavedLimitReset200Response.fromJson(Map<String, dynamic> json) => _$RedeemSavedLimitReset200ResponseFromJson(json);

  Map<String, dynamic> toJson() => _$RedeemSavedLimitReset200ResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

