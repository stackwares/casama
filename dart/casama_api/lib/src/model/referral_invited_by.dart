//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'referral_invited_by.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ReferralInvitedBy {
  /// Returns a new [ReferralInvitedBy] instance.
  ReferralInvitedBy({

    required  this.name,

    required  this.welcomeEarnedUsd,
  });

  @JsonKey(
    
    name: r'name',
    required: true,
    includeIfNull: true,
  )


  final String? name;



  @JsonKey(
    
    name: r'welcome_earned_usd',
    required: true,
    includeIfNull: true,
  )


  final num? welcomeEarnedUsd;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ReferralInvitedBy &&
      other.name == name &&
      other.welcomeEarnedUsd == welcomeEarnedUsd;

    @override
    int get hashCode =>
        (name == null ? 0 : name.hashCode) +
        (welcomeEarnedUsd == null ? 0 : welcomeEarnedUsd.hashCode);

  factory ReferralInvitedBy.fromJson(Map<String, dynamic> json) => _$ReferralInvitedByFromJson(json);

  Map<String, dynamic> toJson() => _$ReferralInvitedByToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

