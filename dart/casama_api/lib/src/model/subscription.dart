//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/billing_source.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'subscription.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Subscription {
  /// Returns a new [Subscription] instance.
  Subscription({

    required  this.id,

    required  this.source_,

    required  this.planCode,

    required  this.status,

    required  this.currentPeriodEnd,

    required  this.cancelAtPeriodEnd,
  });

  @JsonKey(
    
    name: r'id',
    required: true,
    includeIfNull: false,
  )


  final String id;



  @JsonKey(
    
    name: r'source',
    required: true,
    includeIfNull: false,
  )


  final BillingSource source_;



  @JsonKey(
    
    name: r'plan_code',
    required: true,
    includeIfNull: false,
  )


  final String planCode;



  @JsonKey(
    
    name: r'status',
    required: true,
    includeIfNull: false,
  )


  final String status;



  @JsonKey(
    
    name: r'current_period_end',
    required: true,
    includeIfNull: true,
  )


  final DateTime? currentPeriodEnd;



  @JsonKey(
    
    name: r'cancel_at_period_end',
    required: true,
    includeIfNull: false,
  )


  final bool cancelAtPeriodEnd;





    @override
    bool operator ==(Object other) => identical(this, other) || other is Subscription &&
      other.id == id &&
      other.source_ == source_ &&
      other.planCode == planCode &&
      other.status == status &&
      other.currentPeriodEnd == currentPeriodEnd &&
      other.cancelAtPeriodEnd == cancelAtPeriodEnd;

    @override
    int get hashCode =>
        id.hashCode +
        source_.hashCode +
        planCode.hashCode +
        status.hashCode +
        (currentPeriodEnd == null ? 0 : currentPeriodEnd.hashCode) +
        cancelAtPeriodEnd.hashCode;

  factory Subscription.fromJson(Map<String, dynamic> json) => _$SubscriptionFromJson(json);

  Map<String, dynamic> toJson() => _$SubscriptionToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

