//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'redeemed_comp.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class RedeemedComp {
  /// Returns a new [RedeemedComp] instance.
  RedeemedComp({

    required  this.planCode,

    required  this.planName,

    required  this.endsAt,

    required  this.orgId,
  });

  @JsonKey(
    
    name: r'plan_code',
    required: true,
    includeIfNull: false,
  )


  final String planCode;



  @JsonKey(
    
    name: r'plan_name',
    required: true,
    includeIfNull: false,
  )


  final String planName;



  @JsonKey(
    
    name: r'ends_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime endsAt;



  @JsonKey(
    
    name: r'org_id',
    required: true,
    includeIfNull: false,
  )


  final String orgId;





    @override
    bool operator ==(Object other) => identical(this, other) || other is RedeemedComp &&
      other.planCode == planCode &&
      other.planName == planName &&
      other.endsAt == endsAt &&
      other.orgId == orgId;

    @override
    int get hashCode =>
        planCode.hashCode +
        planName.hashCode +
        endsAt.hashCode +
        orgId.hashCode;

  factory RedeemedComp.fromJson(Map<String, dynamic> json) => _$RedeemedCompFromJson(json);

  Map<String, dynamic> toJson() => _$RedeemedCompToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

