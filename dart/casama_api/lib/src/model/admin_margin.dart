//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/admin_margin_by_day_inner.dart';
import 'package:casama_api/src/model/admin_margin_by_kind_inner.dart';
import 'package:casama_api/src/model/admin_margin_top_orgs_inner.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'admin_margin.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminMargin {
  /// Returns a new [AdminMargin] instance.
  AdminMargin({

    required  this.days,

    required  this.chargedUsd,

    required  this.chargedTrackedUsd,

    required  this.upstreamUsd,

    required  this.byDay,

    required  this.byKind,

    required  this.topOrgs,
  });

  @JsonKey(
    
    name: r'days',
    required: true,
    includeIfNull: false,
  )


  final int days;



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



  @JsonKey(
    
    name: r'by_day',
    required: true,
    includeIfNull: false,
  )


  final List<AdminMarginByDayInner> byDay;



  @JsonKey(
    
    name: r'by_kind',
    required: true,
    includeIfNull: false,
  )


  final List<AdminMarginByKindInner> byKind;



  @JsonKey(
    
    name: r'top_orgs',
    required: true,
    includeIfNull: false,
  )


  final List<AdminMarginTopOrgsInner> topOrgs;





    @override
    bool operator ==(Object other) => identical(this, other) || other is AdminMargin &&
      other.days == days &&
      other.chargedUsd == chargedUsd &&
      other.chargedTrackedUsd == chargedTrackedUsd &&
      other.upstreamUsd == upstreamUsd &&
      other.byDay == byDay &&
      other.byKind == byKind &&
      other.topOrgs == topOrgs;

    @override
    int get hashCode =>
        days.hashCode +
        chargedUsd.hashCode +
        chargedTrackedUsd.hashCode +
        upstreamUsd.hashCode +
        byDay.hashCode +
        byKind.hashCode +
        topOrgs.hashCode;

  factory AdminMargin.fromJson(Map<String, dynamic> json) => _$AdminMarginFromJson(json);

  Map<String, dynamic> toJson() => _$AdminMarginToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

