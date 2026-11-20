//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/limit_reset_audience.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'limit_reset_campaign.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class LimitResetCampaign {
  /// Returns a new [LimitResetCampaign] instance.
  LimitResetCampaign({

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

    required  this.id,

    required  this.state,

    required  this.createdBy,

    required  this.createdAt,

    required  this.given,

    required  this.used,

    required  this.expired,

    required  this.refilledUsd,
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



  @JsonKey(
    
    name: r'id',
    required: true,
    includeIfNull: false,
  )


  final String id;



  @JsonKey(
    
    name: r'state',
    required: true,
    includeIfNull: false,
  )


  final String state;



  @JsonKey(
    
    name: r'created_by',
    required: true,
    includeIfNull: false,
  )


  final String createdBy;



  @JsonKey(
    
    name: r'created_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime createdAt;



          // minimum: 0
  @JsonKey(
    
    name: r'given',
    required: true,
    includeIfNull: false,
  )


  final int given;



          // minimum: 0
  @JsonKey(
    
    name: r'used',
    required: true,
    includeIfNull: false,
  )


  final int used;



          // minimum: 0
  @JsonKey(
    
    name: r'expired',
    required: true,
    includeIfNull: false,
  )


  final int expired;



          // minimum: 0
  @JsonKey(
    
    name: r'refilled_usd',
    required: true,
    includeIfNull: false,
  )


  final num refilledUsd;





    @override
    bool operator ==(Object other) => identical(this, other) || other is LimitResetCampaign &&
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
      other.notifyReminder == notifyReminder &&
      other.id == id &&
      other.state == state &&
      other.createdBy == createdBy &&
      other.createdAt == createdAt &&
      other.given == given &&
      other.used == used &&
      other.expired == expired &&
      other.refilledUsd == refilledUsd;

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
        notifyReminder.hashCode +
        id.hashCode +
        state.hashCode +
        createdBy.hashCode +
        createdAt.hashCode +
        given.hashCode +
        used.hashCode +
        expired.hashCode +
        refilledUsd.hashCode;

  factory LimitResetCampaign.fromJson(Map<String, dynamic> json) => _$LimitResetCampaignFromJson(json);

  Map<String, dynamic> toJson() => _$LimitResetCampaignToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

