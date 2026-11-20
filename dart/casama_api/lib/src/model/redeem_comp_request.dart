//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'redeem_comp_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class RedeemCompRequest {
  /// Returns a new [RedeemCompRequest] instance.
  RedeemCompRequest({

    required  this.code,

    required  this.orgId,
  });

  @JsonKey(
    
    name: r'code',
    required: true,
    includeIfNull: false,
  )


  final String code;



  @JsonKey(
    
    name: r'org_id',
    required: true,
    includeIfNull: false,
  )


  final String orgId;





    @override
    bool operator ==(Object other) => identical(this, other) || other is RedeemCompRequest &&
      other.code == code &&
      other.orgId == orgId;

    @override
    int get hashCode =>
        code.hashCode +
        orgId.hashCode;

  factory RedeemCompRequest.fromJson(Map<String, dynamic> json) => _$RedeemCompRequestFromJson(json);

  Map<String, dynamic> toJson() => _$RedeemCompRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

