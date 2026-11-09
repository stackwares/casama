//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:kasama_api/src/model/billing_usage_item.dart';
import 'package:kasama_api/src/model/credit_entry.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'billing_usage.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class BillingUsage {
  /// Returns a new [BillingUsage] instance.
  BillingUsage({

    required  this.periodStart,

    required  this.items,

    required  this.totalUsd,

    required  this.credits,
  });

  @JsonKey(
    
    name: r'period_start',
    required: true,
    includeIfNull: false,
  )


  final DateTime periodStart;



  @JsonKey(
    
    name: r'items',
    required: true,
    includeIfNull: false,
  )


  final List<BillingUsageItem> items;



  @JsonKey(
    
    name: r'total_usd',
    required: true,
    includeIfNull: false,
  )


  final num totalUsd;



  @JsonKey(
    
    name: r'credits',
    required: true,
    includeIfNull: false,
  )


  final List<CreditEntry> credits;





    @override
    bool operator ==(Object other) => identical(this, other) || other is BillingUsage &&
      other.periodStart == periodStart &&
      other.items == items &&
      other.totalUsd == totalUsd &&
      other.credits == credits;

    @override
    int get hashCode =>
        periodStart.hashCode +
        items.hashCode +
        totalUsd.hashCode +
        credits.hashCode;

  factory BillingUsage.fromJson(Map<String, dynamic> json) => _$BillingUsageFromJson(json);

  Map<String, dynamic> toJson() => _$BillingUsageToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

