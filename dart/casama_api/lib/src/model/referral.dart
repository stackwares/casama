//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/referral_invited_by.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'referral.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Referral {
  /// Returns a new [Referral] instance.
  Referral({

    required  this.enabled,

    required  this.code,

    required  this.link,

    required  this.rewardUsd,

    required  this.welcomeUsd,

    required  this.rewardCap,

    required  this.invited,

    required  this.rewarded,

    required  this.pending,

    required  this.earnedUsd,

    required  this.invitedBy,

    required  this.redeemUntil,
  });

  @JsonKey(
    
    name: r'enabled',
    required: true,
    includeIfNull: false,
  )


  final bool enabled;



  @JsonKey(
    
    name: r'code',
    required: true,
    includeIfNull: true,
  )


  final String? code;



  @JsonKey(
    
    name: r'link',
    required: true,
    includeIfNull: true,
  )


  final String? link;



  @JsonKey(
    
    name: r'reward_usd',
    required: true,
    includeIfNull: false,
  )


  final num rewardUsd;



  @JsonKey(
    
    name: r'welcome_usd',
    required: true,
    includeIfNull: false,
  )


  final num welcomeUsd;



  @JsonKey(
    
    name: r'reward_cap',
    required: true,
    includeIfNull: false,
  )


  final int rewardCap;



  @JsonKey(
    
    name: r'invited',
    required: true,
    includeIfNull: false,
  )


  final int invited;



  @JsonKey(
    
    name: r'rewarded',
    required: true,
    includeIfNull: false,
  )


  final int rewarded;



  @JsonKey(
    
    name: r'pending',
    required: true,
    includeIfNull: false,
  )


  final int pending;



  @JsonKey(
    
    name: r'earned_usd',
    required: true,
    includeIfNull: false,
  )


  final num earnedUsd;



  @JsonKey(
    
    name: r'invited_by',
    required: true,
    includeIfNull: true,
  )


  final ReferralInvitedBy? invitedBy;



  @JsonKey(
    
    name: r'redeem_until',
    required: true,
    includeIfNull: true,
  )


  final DateTime? redeemUntil;





    @override
    bool operator ==(Object other) => identical(this, other) || other is Referral &&
      other.enabled == enabled &&
      other.code == code &&
      other.link == link &&
      other.rewardUsd == rewardUsd &&
      other.welcomeUsd == welcomeUsd &&
      other.rewardCap == rewardCap &&
      other.invited == invited &&
      other.rewarded == rewarded &&
      other.pending == pending &&
      other.earnedUsd == earnedUsd &&
      other.invitedBy == invitedBy &&
      other.redeemUntil == redeemUntil;

    @override
    int get hashCode =>
        enabled.hashCode +
        (code == null ? 0 : code.hashCode) +
        (link == null ? 0 : link.hashCode) +
        rewardUsd.hashCode +
        welcomeUsd.hashCode +
        rewardCap.hashCode +
        invited.hashCode +
        rewarded.hashCode +
        pending.hashCode +
        earnedUsd.hashCode +
        (invitedBy == null ? 0 : invitedBy.hashCode) +
        (redeemUntil == null ? 0 : redeemUntil.hashCode);

  factory Referral.fromJson(Map<String, dynamic> json) => _$ReferralFromJson(json);

  Map<String, dynamic> toJson() => _$ReferralToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

