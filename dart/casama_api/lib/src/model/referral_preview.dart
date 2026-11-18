//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'referral_preview.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ReferralPreview {
  /// Returns a new [ReferralPreview] instance.
  ReferralPreview({

    required  this.inviterName,

    required  this.rewardUsd,

    required  this.welcomeUsd,
  });

  @JsonKey(
    
    name: r'inviter_name',
    required: true,
    includeIfNull: true,
  )


  final String? inviterName;



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





    @override
    bool operator ==(Object other) => identical(this, other) || other is ReferralPreview &&
      other.inviterName == inviterName &&
      other.rewardUsd == rewardUsd &&
      other.welcomeUsd == welcomeUsd;

    @override
    int get hashCode =>
        (inviterName == null ? 0 : inviterName.hashCode) +
        rewardUsd.hashCode +
        welcomeUsd.hashCode;

  factory ReferralPreview.fromJson(Map<String, dynamic> json) => _$ReferralPreviewFromJson(json);

  Map<String, dynamic> toJson() => _$ReferralPreviewToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

