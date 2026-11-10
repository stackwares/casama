//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'admin_org.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminOrg {
  /// Returns a new [AdminOrg] instance.
  AdminOrg({

    required  this.id,

    required  this.name,

    required  this.planCode,

    required  this.limits,

    required  this.members,

    required  this.bots,

    required  this.cost30dUsd,

     this.suspendedAt,

     this.suspendedReason,
  });

  @JsonKey(
    
    name: r'id',
    required: true,
    includeIfNull: false,
  )


  final String id;



  @JsonKey(
    
    name: r'name',
    required: true,
    includeIfNull: false,
  )


  final String name;



  @JsonKey(
    
    name: r'plan_code',
    required: true,
    includeIfNull: true,
  )


  final String? planCode;



  @JsonKey(
    
    name: r'limits',
    required: true,
    includeIfNull: false,
  )


  final Map<String, num> limits;



  @JsonKey(
    
    name: r'members',
    required: true,
    includeIfNull: false,
  )


  final int members;



  @JsonKey(
    
    name: r'bots',
    required: true,
    includeIfNull: false,
  )


  final int bots;



  @JsonKey(
    
    name: r'cost_30d_usd',
    required: true,
    includeIfNull: false,
  )


  final num cost30dUsd;



  @JsonKey(
    
    name: r'suspended_at',
    required: false,
    includeIfNull: false,
  )


  final String? suspendedAt;



  @JsonKey(
    
    name: r'suspended_reason',
    required: false,
    includeIfNull: false,
  )


  final String? suspendedReason;





    @override
    bool operator ==(Object other) => identical(this, other) || other is AdminOrg &&
      other.id == id &&
      other.name == name &&
      other.planCode == planCode &&
      other.limits == limits &&
      other.members == members &&
      other.bots == bots &&
      other.cost30dUsd == cost30dUsd &&
      other.suspendedAt == suspendedAt &&
      other.suspendedReason == suspendedReason;

    @override
    int get hashCode =>
        id.hashCode +
        name.hashCode +
        (planCode == null ? 0 : planCode.hashCode) +
        limits.hashCode +
        members.hashCode +
        bots.hashCode +
        cost30dUsd.hashCode +
        (suspendedAt == null ? 0 : suspendedAt.hashCode) +
        (suspendedReason == null ? 0 : suspendedReason.hashCode);

  factory AdminOrg.fromJson(Map<String, dynamic> json) => _$AdminOrgFromJson(json);

  Map<String, dynamic> toJson() => _$AdminOrgToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

