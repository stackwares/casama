//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/admin_credit_pack.dart';
import 'package:casama_api/src/model/billing_settings.dart';
import 'package:casama_api/src/model/admin_plan.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'admin_pricing.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminPricing {
  /// Returns a new [AdminPricing] instance.
  AdminPricing({

    required  this.billingEnabled,

    required  this.plans,

    required  this.packs,

    required  this.settings,
  });

  @JsonKey(
    
    name: r'billing_enabled',
    required: true,
    includeIfNull: false,
  )


  final bool billingEnabled;



  @JsonKey(
    
    name: r'plans',
    required: true,
    includeIfNull: false,
  )


  final List<AdminPlan> plans;



  @JsonKey(
    
    name: r'packs',
    required: true,
    includeIfNull: false,
  )


  final List<AdminCreditPack> packs;



  @JsonKey(
    
    name: r'settings',
    required: true,
    includeIfNull: false,
  )


  final BillingSettings settings;





    @override
    bool operator ==(Object other) => identical(this, other) || other is AdminPricing &&
      other.billingEnabled == billingEnabled &&
      other.plans == plans &&
      other.packs == packs &&
      other.settings == settings;

    @override
    int get hashCode =>
        billingEnabled.hashCode +
        plans.hashCode +
        packs.hashCode +
        settings.hashCode;

  factory AdminPricing.fromJson(Map<String, dynamic> json) => _$AdminPricingFromJson(json);

  Map<String, dynamic> toJson() => _$AdminPricingToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

