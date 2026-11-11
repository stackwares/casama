//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/subscription.dart';
import 'package:casama_api/src/model/billing_source.dart';
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

    required  this.creditsUsd,

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



  @JsonKey(
    
    name: r'credits_usd',
    required: true,
    includeIfNull: false,
  )


  final num creditsUsd;



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
      other.creditsUsd == creditsUsd &&
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
        creditsUsd.hashCode +
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


