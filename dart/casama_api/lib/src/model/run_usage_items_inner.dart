//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'run_usage_items_inner.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class RunUsageItemsInner {
  /// Returns a new [RunUsageItemsInner] instance.
  RunUsageItemsInner({

    required  this.kind,

    required  this.model,

    required  this.source_,

    required  this.billable,

    required  this.quantity,

    required  this.costUsd,

     this.upstreamCostUsd,
  });

  @JsonKey(
    
    name: r'kind',
    required: true,
    includeIfNull: false,
  )


  final String kind;



  @JsonKey(
    
    name: r'model',
    required: true,
    includeIfNull: true,
  )


  final String? model;



  @JsonKey(
    
    name: r'source',
    required: true,
    includeIfNull: false,
  )


  final RunUsageItemsInnerSource_Enum source_;



  @JsonKey(
    
    name: r'billable',
    required: true,
    includeIfNull: false,
  )


  final bool billable;



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



      /// Instance owner only, like the total
  @JsonKey(
    
    name: r'upstream_cost_usd',
    required: false,
    includeIfNull: false,
  )


  final num? upstreamCostUsd;





    @override
    bool operator ==(Object other) => identical(this, other) || other is RunUsageItemsInner &&
      other.kind == kind &&
      other.model == model &&
      other.source_ == source_ &&
      other.billable == billable &&
      other.quantity == quantity &&
      other.costUsd == costUsd &&
      other.upstreamCostUsd == upstreamCostUsd;

    @override
    int get hashCode =>
        kind.hashCode +
        (model == null ? 0 : model.hashCode) +
        source_.hashCode +
        billable.hashCode +
        quantity.hashCode +
        costUsd.hashCode +
        (upstreamCostUsd == null ? 0 : upstreamCostUsd.hashCode);

  factory RunUsageItemsInner.fromJson(Map<String, dynamic> json) => _$RunUsageItemsInnerFromJson(json);

  Map<String, dynamic> toJson() => _$RunUsageItemsInnerToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum RunUsageItemsInnerSource_Enum {
@JsonValue(r'key')
key(r'key'),
@JsonValue(r'chatgpt_plan')
chatgptPlan(r'chatgpt_plan');

const RunUsageItemsInnerSource_Enum(this.value);

final String value;

@override
String toString() => value;
}


