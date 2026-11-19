//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'create_invite_campaign_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CreateInviteCampaignRequest {
  /// Returns a new [CreateInviteCampaignRequest] instance.
  CreateInviteCampaignRequest({

    required  this.code,

    required  this.label,

    required  this.maxUses,

     this.perDay,

     this.startsAt,

     this.expiresAt,
  });

  @JsonKey(
    
    name: r'code',
    required: true,
    includeIfNull: false,
  )


  final String code;



  @JsonKey(
    
    name: r'label',
    required: true,
    includeIfNull: false,
  )


  final String label;



          // minimum: 0
          // maximum: 1000000
  @JsonKey(
    
    name: r'max_uses',
    required: true,
    includeIfNull: false,
  )


  final int maxUses;



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





    @override
    bool operator ==(Object other) => identical(this, other) || other is CreateInviteCampaignRequest &&
      other.code == code &&
      other.label == label &&
      other.maxUses == maxUses &&
      other.perDay == perDay &&
      other.startsAt == startsAt &&
      other.expiresAt == expiresAt;

    @override
    int get hashCode =>
        code.hashCode +
        label.hashCode +
        maxUses.hashCode +
        (perDay == null ? 0 : perDay.hashCode) +
        (startsAt == null ? 0 : startsAt.hashCode) +
        (expiresAt == null ? 0 : expiresAt.hashCode);

  factory CreateInviteCampaignRequest.fromJson(Map<String, dynamic> json) => _$CreateInviteCampaignRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CreateInviteCampaignRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

