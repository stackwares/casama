//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'update_invite_campaign_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class UpdateInviteCampaignRequest {
  /// Returns a new [UpdateInviteCampaignRequest] instance.
  UpdateInviteCampaignRequest({

     this.label,

     this.maxUses,

     this.perDay,

     this.startsAt,

     this.expiresAt,

     this.disabled,
  });

  @JsonKey(
    
    name: r'label',
    required: false,
    includeIfNull: false,
  )


  final String? label;



          // minimum: 0
          // maximum: 1000000
  @JsonKey(
    
    name: r'max_uses',
    required: false,
    includeIfNull: false,
  )


  final int? maxUses;



          // minimum: 1
          // maximum: 1000000
  @JsonKey(
    
    name: r'per_day',
    required: false,
    includeIfNull: false,
  )


  final int? perDay;



  @JsonKey(
    
    name: r'starts_at',
    required: false,
    includeIfNull: false,
  )


  final DateTime? startsAt;



  @JsonKey(
    
    name: r'expires_at',
    required: false,
    includeIfNull: false,
  )


  final DateTime? expiresAt;



  @JsonKey(
    
    name: r'disabled',
    required: false,
    includeIfNull: false,
  )


  final bool? disabled;





    @override
    bool operator ==(Object other) => identical(this, other) || other is UpdateInviteCampaignRequest &&
      other.label == label &&
      other.maxUses == maxUses &&
      other.perDay == perDay &&
      other.startsAt == startsAt &&
      other.expiresAt == expiresAt &&
      other.disabled == disabled;

    @override
    int get hashCode =>
        label.hashCode +
        maxUses.hashCode +
        (perDay == null ? 0 : perDay.hashCode) +
        (startsAt == null ? 0 : startsAt.hashCode) +
        (expiresAt == null ? 0 : expiresAt.hashCode) +
        disabled.hashCode;

  factory UpdateInviteCampaignRequest.fromJson(Map<String, dynamic> json) => _$UpdateInviteCampaignRequestFromJson(json);

  Map<String, dynamic> toJson() => _$UpdateInviteCampaignRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

