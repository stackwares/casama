//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'saved_limit_reset.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SavedLimitReset {
  /// Returns a new [SavedLimitReset] instance.
  SavedLimitReset({

    required  this.id,

    required  this.campaignId,

    required  this.message,

    required  this.expiresAt,

    required  this.refillUsd,

    required  this.resetDaily,

    required  this.resetComputer,

    required  this.canUse,

    required  this.unavailableReason,
  });

  @JsonKey(
    
    name: r'id',
    required: true,
    includeIfNull: false,
  )


  final String id;



  @JsonKey(
    
    name: r'campaign_id',
    required: true,
    includeIfNull: true,
  )


  final String? campaignId;



  @JsonKey(
    
    name: r'message',
    required: true,
    includeIfNull: false,
  )


  final String message;



  @JsonKey(
    
    name: r'expires_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime expiresAt;



          // minimum: 0
          // maximum: 1000000
  @JsonKey(
    
    name: r'refill_usd',
    required: true,
    includeIfNull: false,
  )


  final num refillUsd;



  @JsonKey(
    
    name: r'reset_daily',
    required: true,
    includeIfNull: false,
  )


  final bool resetDaily;



  @JsonKey(
    
    name: r'reset_computer',
    required: true,
    includeIfNull: false,
  )


  final bool resetComputer;



  @JsonKey(
    
    name: r'can_use',
    required: true,
    includeIfNull: false,
  )


  final bool canUse;



      /// Why it can't be used now: owner_required, paused, period_limit, budget, nothing_to_refill or no_billing_period; null when it can
  @JsonKey(
    
    name: r'unavailable_reason',
    required: true,
    includeIfNull: true,
  )


  final String? unavailableReason;





    @override
    bool operator ==(Object other) => identical(this, other) || other is SavedLimitReset &&
      other.id == id &&
      other.campaignId == campaignId &&
      other.message == message &&
      other.expiresAt == expiresAt &&
      other.refillUsd == refillUsd &&
      other.resetDaily == resetDaily &&
      other.resetComputer == resetComputer &&
      other.canUse == canUse &&
      other.unavailableReason == unavailableReason;

    @override
    int get hashCode =>
        id.hashCode +
        (campaignId == null ? 0 : campaignId.hashCode) +
        message.hashCode +
        expiresAt.hashCode +
        refillUsd.hashCode +
        resetDaily.hashCode +
        resetComputer.hashCode +
        canUse.hashCode +
        (unavailableReason == null ? 0 : unavailableReason.hashCode);

  factory SavedLimitReset.fromJson(Map<String, dynamic> json) => _$SavedLimitResetFromJson(json);

  Map<String, dynamic> toJson() => _$SavedLimitResetToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

