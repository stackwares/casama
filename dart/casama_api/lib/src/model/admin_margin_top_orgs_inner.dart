//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'admin_margin_top_orgs_inner.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminMarginTopOrgsInner {
  /// Returns a new [AdminMarginTopOrgsInner] instance.
  AdminMarginTopOrgsInner({

    required  this.orgId,

    required  this.name,

    required  this.planCode,

    required  this.chargedUsd,

    required  this.chargedTrackedUsd,

    required  this.upstreamUsd,
  });

  @JsonKey(
    
    name: r'org_id',
    required: true,
    includeIfNull: false,
  )


  final String orgId;



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



      /// Taken from credits for usage
  @JsonKey(
    
    name: r'charged_usd',
    required: true,
    includeIfNull: false,
  )


  final num chargedUsd;



      /// The charged part whose cost is known per row (not computers)
  @JsonKey(
    
    name: r'charged_tracked_usd',
    required: true,
    includeIfNull: false,
  )


  final num chargedTrackedUsd;



      /// What the server paid its providers, fees included, also for waived rows
  @JsonKey(
    
    name: r'upstream_usd',
    required: true,
    includeIfNull: false,
  )


  final num upstreamUsd;





    @override
    bool operator ==(Object other) => identical(this, other) || other is AdminMarginTopOrgsInner &&
      other.orgId == orgId &&
      other.name == name &&
      other.planCode == planCode &&
      other.chargedUsd == chargedUsd &&
      other.chargedTrackedUsd == chargedTrackedUsd &&
      other.upstreamUsd == upstreamUsd;

    @override
    int get hashCode =>
        orgId.hashCode +
        name.hashCode +
        (planCode == null ? 0 : planCode.hashCode) +
        chargedUsd.hashCode +
        chargedTrackedUsd.hashCode +
        upstreamUsd.hashCode;

  factory AdminMarginTopOrgsInner.fromJson(Map<String, dynamic> json) => _$AdminMarginTopOrgsInnerFromJson(json);

  Map<String, dynamic> toJson() => _$AdminMarginTopOrgsInnerToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

