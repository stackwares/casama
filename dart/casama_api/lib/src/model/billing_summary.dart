//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/billing_summary_comp.dart';
import 'package:casama_api/src/model/billing_summary_daily.dart';
import 'package:casama_api/src/model/billing_summary_computer_hours.dart';
import 'package:casama_api/src/model/subscription.dart';
import 'package:casama_api/src/model/billing_source.dart';
import 'package:casama_api/src/model/saved_limit_reset.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'billing_summary.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class BillingSummary {
  /// Returns a new [BillingSummary] instance.
  BillingSummary({

    required  this.enabled,

    required  this.planCode,

    required  this.planName,

    required  this.interval,

    required  this.limits,

    required  this.unlimited,

    required  this.validUntil,

    required  this.source_,

    required  this.cancelAtPeriodEnd,

     this.extraSeats,

     this.trialAvailable,

     this.resets,

    required  this.creditsUsd,

     this.daily,

     this.computerHours,

     this.comp,

     this.casamaModels,

     this.casamaModelsNote,

    required  this.subscriptions,

    required  this.providers,
  });

      /// False on self-hosted servers: no paywall
  @JsonKey(
    
    name: r'enabled',
    required: true,
    includeIfNull: false,
  )


  final bool enabled;



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
    
    name: r'interval',
    required: true,
    includeIfNull: false,
  )


  final String interval;



  @JsonKey(
    
    name: r'limits',
    required: true,
    includeIfNull: false,
  )


  final Map<String, num> limits;



  @JsonKey(
    
    name: r'unlimited',
    required: true,
    includeIfNull: false,
  )


  final bool unlimited;



  @JsonKey(
    
    name: r'valid_until',
    required: true,
    includeIfNull: true,
  )


  final DateTime? validUntil;



  @JsonKey(
    
    name: r'source',
    required: true,
    includeIfNull: false,
  )


  final BillingSummarySource_Enum source_;



  @JsonKey(
    
    name: r'cancel_at_period_end',
    required: true,
    includeIfNull: false,
  )


  final bool cancelAtPeriodEnd;



      /// People paid for beyond the plan's seats (D-249)
  @JsonKey(
    
    name: r'extra_seats',
    required: false,
    includeIfNull: false,
  )


  final int? extraSeats;



      /// The owner can still start a plan's free trial (D-249)
  @JsonKey(
    
    name: r'trial_available',
    required: false,
    includeIfNull: false,
  )


  final bool? trialAvailable;



  @JsonKey(
    
    name: r'resets',
    required: false,
    includeIfNull: false,
  )


  final List<SavedLimitReset>? resets;



  @JsonKey(
    
    name: r'credits_usd',
    required: true,
    includeIfNull: false,
  )


  final num creditsUsd;



  @JsonKey(
    
    name: r'daily',
    required: false,
    includeIfNull: false,
  )


  final BillingSummaryDaily? daily;



  @JsonKey(
    
    name: r'computer_hours',
    required: false,
    includeIfNull: false,
  )


  final BillingSummaryComputerHours? computerHours;



  @JsonKey(
    
    name: r'comp',
    required: false,
    includeIfNull: false,
  )


  final BillingSummaryComp? comp;



      /// Whether Casama's own model keys are available on this workspace's plan (docs/OWN-KEYS-PLAN.md §6)
  @JsonKey(
    
    name: r'casama_models',
    required: false,
    includeIfNull: false,
  )


  final BillingSummaryCasamaModelsEnum? casamaModels;



      /// Optional note from the instance owner when Casama's models are turned off (§3.3)
  @JsonKey(
    
    name: r'casama_models_note',
    required: false,
    includeIfNull: false,
  )


  final String? casamaModelsNote;



  @JsonKey(
    
    name: r'subscriptions',
    required: true,
    includeIfNull: false,
  )


  final List<Subscription> subscriptions;



  @JsonKey(
    
    name: r'providers',
    required: true,
    includeIfNull: false,
  )


  final List<BillingSource> providers;





    @override
    bool operator ==(Object other) => identical(this, other) || other is BillingSummary &&
      other.enabled == enabled &&
      other.planCode == planCode &&
      other.planName == planName &&
      other.interval == interval &&
      other.limits == limits &&
      other.unlimited == unlimited &&
      other.validUntil == validUntil &&
      other.source_ == source_ &&
      other.cancelAtPeriodEnd == cancelAtPeriodEnd &&
      other.extraSeats == extraSeats &&
      other.trialAvailable == trialAvailable &&
      other.resets == resets &&
      other.creditsUsd == creditsUsd &&
      other.daily == daily &&
      other.computerHours == computerHours &&
      other.comp == comp &&
      other.casamaModels == casamaModels &&
      other.casamaModelsNote == casamaModelsNote &&
      other.subscriptions == subscriptions &&
      other.providers == providers;

    @override
    int get hashCode =>
        enabled.hashCode +
        planCode.hashCode +
        planName.hashCode +
        interval.hashCode +
        limits.hashCode +
        unlimited.hashCode +
        (validUntil == null ? 0 : validUntil.hashCode) +
        source_.hashCode +
        cancelAtPeriodEnd.hashCode +
        extraSeats.hashCode +
        trialAvailable.hashCode +
        resets.hashCode +
        creditsUsd.hashCode +
        (daily == null ? 0 : daily.hashCode) +
        (computerHours == null ? 0 : computerHours.hashCode) +
        (comp == null ? 0 : comp.hashCode) +
        casamaModels.hashCode +
        (casamaModelsNote == null ? 0 : casamaModelsNote.hashCode) +
        subscriptions.hashCode +
        providers.hashCode;

  factory BillingSummary.fromJson(Map<String, dynamic> json) => _$BillingSummaryFromJson(json);

  Map<String, dynamic> toJson() => _$BillingSummaryToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum BillingSummarySource_Enum {
@JsonValue(r'default')
default_(r'default'),
@JsonValue(r'dodo')
dodo(r'dodo'),
@JsonValue(r'app_store')
appStore(r'app_store'),
@JsonValue(r'google_play')
googlePlay(r'google_play');

const BillingSummarySource_Enum(this.value);

final String value;

@override
String toString() => value;
}


/// Whether Casama's own model keys are available on this workspace's plan (docs/OWN-KEYS-PLAN.md §6)
enum BillingSummaryCasamaModelsEnum {
    /// Whether Casama's own model keys are available on this workspace's plan (docs/OWN-KEYS-PLAN.md §6)
@JsonValue(r'on')
on_(r'on'),
    /// Whether Casama's own model keys are available on this workspace's plan (docs/OWN-KEYS-PLAN.md §6)
@JsonValue(r'off')
off(r'off');

const BillingSummaryCasamaModelsEnum(this.value);

final String value;

@override
String toString() => value;
}


