//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/limit_reset_audience.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'limit_reset_campaign_input.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class LimitResetCampaignInput {
  /// Returns a new [LimitResetCampaignInput] instance.
  LimitResetCampaignInput({

    required  this.name,

    required  this.message,

    required  this.audience,

    required  this.startsAt,

    required  this.expiresAt,

     this.refillPercent = 100,

     this.resetDaily = true,

     this.resetComputer = false,

     this.maxPerUseUsd,

     this.budgetUsd,

     this.notifyArrival = true,

     this.notifyReminder = true,
  });

  @JsonKey(
    
    name: r'name',
    required: true,
    includeIfNull: false,
  )


  final String name;



  @JsonKey(
    
    name: r'message',
    required: true,
    includeIfNull: false,
  )


  final String message;



  @JsonKey(
    
    name: r'audience',
    required: true,
    includeIfNull: false,
  )


  final LimitResetAudience audience;



  @JsonKey(
    
    name: r'starts_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime startsAt;



  @JsonKey(
    
    name: r'expires_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime expiresAt;



          // minimum: 10
          // maximum: 100
  @JsonKey(
    defaultValue: 100,
    name: r'refill_percent',
    required: false,
    includeIfNull: false,
  )


  final int? refillPercent;



  @JsonKey(
    defaultValue: true,
    name: r'reset_daily',
    required: false,
    includeIfNull: false,
  )


  final bool? resetDaily;



  @JsonKey(
    defaultValue: false,
    name: r'reset_computer',
    required: false,
    includeIfNull: false,
  )


  final bool? resetComputer;



          // minimum: 0
          // maximum: 1000000
  @JsonKey(
    
    name: r'max_per_use_usd',
    required: false,
    includeIfNull: false,
  )


  final num? maxPerUseUsd;



          // minimum: 0
          // maximum: 1000000
  @JsonKey(
    
    name: r'budget_usd',
    required: false,
    includeIfNull: false,
  )


  final num? budgetUsd;



  @JsonKey(
    defaultValue: true,
    name: r'notify_arrival',
    required: false,
    includeIfNull: false,
  )


  final bool? notifyArrival;



  @JsonKey(
    defaultValue: true,
    name: r'notify_reminder',
    required: false,
    includeIfNull: false,
  )


  final bool? notifyReminder;





    @override
    bool operator ==(Object other) => identical(this, other) || other is LimitResetCampaignInput &&
      other.name == name &&
      other.message == message &&
      other.audience == audience &&
      other.startsAt == startsAt &&
      other.expiresAt == expiresAt &&
      other.refillPercent == refillPercent &&
      other.resetDaily == resetDaily &&
      other.resetComputer == resetComputer &&
      other.maxPerUseUsd == maxPerUseUsd &&
      other.budgetUsd == budgetUsd &&
      other.notifyArrival == notifyArrival &&
      other.notifyReminder == notifyReminder;

    @override
    int get hashCode =>
        name.hashCode +
        message.hashCode +
        audience.hashCode +
        startsAt.hashCode +
        expiresAt.hashCode +
        refillPercent.hashCode +
        resetDaily.hashCode +
        resetComputer.hashCode +
        (maxPerUseUsd == null ? 0 : maxPerUseUsd.hashCode) +
        (budgetUsd == null ? 0 : budgetUsd.hashCode) +
        notifyArrival.hashCode +
        notifyReminder.hashCode;

  factory LimitResetCampaignInput.fromJson(Map<String, dynamic> json) => _$LimitResetCampaignInputFromJson(json);

  Map<String, dynamic> toJson() => _$LimitResetCampaignInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

