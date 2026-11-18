//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'glance_credits.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class GlanceCredits {
  /// Returns a new [GlanceCredits] instance.
  GlanceCredits({

    required  this.billing,

    required  this.unlimited,

    required  this.plan,

    required  this.usedShare,

    required  this.leftUsd,

    required  this.todayUsd,

    required  this.monthUsd,

    required  this.dailyCapUsd,

    required  this.dailyUsedUsd,

    required  this.resetsAt,
  });

  @JsonKey(
    
    name: r'billing',
    required: true,
    includeIfNull: false,
  )


  final bool billing;



  @JsonKey(
    
    name: r'unlimited',
    required: true,
    includeIfNull: false,
  )


  final bool unlimited;



  @JsonKey(
    
    name: r'plan',
    required: true,
    includeIfNull: true,
  )


  final String? plan;



          // minimum: 0
          // maximum: 1
  @JsonKey(
    
    name: r'used_share',
    required: true,
    includeIfNull: true,
  )


  final num? usedShare;



  @JsonKey(
    
    name: r'left_usd',
    required: true,
    includeIfNull: true,
  )


  final num? leftUsd;



  @JsonKey(
    
    name: r'today_usd',
    required: true,
    includeIfNull: false,
  )


  final num todayUsd;



  @JsonKey(
    
    name: r'month_usd',
    required: true,
    includeIfNull: false,
  )


  final num monthUsd;



  @JsonKey(
    
    name: r'daily_cap_usd',
    required: true,
    includeIfNull: true,
  )


  final num? dailyCapUsd;



  @JsonKey(
    
    name: r'daily_used_usd',
    required: true,
    includeIfNull: true,
  )


  final num? dailyUsedUsd;



  @JsonKey(
    
    name: r'resets_at',
    required: true,
    includeIfNull: true,
  )


  final DateTime? resetsAt;





    @override
    bool operator ==(Object other) => identical(this, other) || other is GlanceCredits &&
      other.billing == billing &&
      other.unlimited == unlimited &&
      other.plan == plan &&
      other.usedShare == usedShare &&
      other.leftUsd == leftUsd &&
      other.todayUsd == todayUsd &&
      other.monthUsd == monthUsd &&
      other.dailyCapUsd == dailyCapUsd &&
      other.dailyUsedUsd == dailyUsedUsd &&
      other.resetsAt == resetsAt;

    @override
    int get hashCode =>
        billing.hashCode +
        unlimited.hashCode +
        (plan == null ? 0 : plan.hashCode) +
        (usedShare == null ? 0 : usedShare.hashCode) +
        (leftUsd == null ? 0 : leftUsd.hashCode) +
        todayUsd.hashCode +
        monthUsd.hashCode +
        (dailyCapUsd == null ? 0 : dailyCapUsd.hashCode) +
        (dailyUsedUsd == null ? 0 : dailyUsedUsd.hashCode) +
        (resetsAt == null ? 0 : resetsAt.hashCode);

  factory GlanceCredits.fromJson(Map<String, dynamic> json) => _$GlanceCreditsFromJson(json);

  Map<String, dynamic> toJson() => _$GlanceCreditsToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

