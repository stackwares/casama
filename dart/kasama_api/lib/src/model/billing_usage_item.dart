//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'billing_usage_item.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class BillingUsageItem {
  /// Returns a new [BillingUsageItem] instance.
  BillingUsageItem({

    required  this.kind,

    required  this.instance,

    required  this.quantity,

    required  this.costUsd,
  });

  @JsonKey(
    
    name: r'kind',
    required: true,
    includeIfNull: false,
  )


  final String kind;



      /// Cloud Connect instance, if any
  @JsonKey(
    
    name: r'instance',
    required: true,
    includeIfNull: true,
  )


  final String? instance;



  @JsonKey(
    
    name: r'quantity',
    required: true,
    includeIfNull: false,
  )


  final num quantity;



  @JsonKey(
    
    name: r'cost_usd',
    required: true,
    includeIfNull: false,
  )


  final num costUsd;





    @override
    bool operator ==(Object other) => identical(this, other) || other is BillingUsageItem &&
      other.kind == kind &&
      other.instance == instance &&
      other.quantity == quantity &&
      other.costUsd == costUsd;

    @override
    int get hashCode =>
        kind.hashCode +
        (instance == null ? 0 : instance.hashCode) +
        quantity.hashCode +
        costUsd.hashCode;

  factory BillingUsageItem.fromJson(Map<String, dynamic> json) => _$BillingUsageItemFromJson(json);

  Map<String, dynamic> toJson() => _$BillingUsageItemToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

