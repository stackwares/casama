//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'invite_campaign.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class InviteCampaign {
  /// Returns a new [InviteCampaign] instance.
  InviteCampaign({

    required  this.code,

    required  this.label,

    required  this.maxUses,

    required  this.used,

    required  this.perDay,

    required  this.startsAt,

    required  this.expiresAt,

    required  this.disabled,

    required  this.createdAt,

    required  this.link,
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



  @JsonKey(
    
    name: r'max_uses',
    required: true,
    includeIfNull: false,
  )


  final int maxUses;



  @JsonKey(
    
    name: r'used',
    required: true,
    includeIfNull: false,
  )


  final int used;



  @JsonKey(
    
    name: r'per_day',
    required: true,
    includeIfNull: true,
  )


  final int? perDay;



  @JsonKey(
    
    name: r'starts_at',
    required: true,
    includeIfNull: true,
  )


  final DateTime? startsAt;



  @JsonKey(
    
    name: r'expires_at',
    required: true,
    includeIfNull: true,
  )


  final DateTime? expiresAt;



  @JsonKey(
    
    name: r'disabled',
    required: true,
    includeIfNull: false,
  )


  final bool disabled;



  @JsonKey(
    
    name: r'created_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime createdAt;



  @JsonKey(
    
    name: r'link',
    required: true,
    includeIfNull: false,
  )


  final String link;





    @override
    bool operator ==(Object other) => identical(this, other) || other is InviteCampaign &&
      other.code == code &&
      other.label == label &&
      other.maxUses == maxUses &&
      other.used == used &&
      other.perDay == perDay &&
      other.startsAt == startsAt &&
      other.expiresAt == expiresAt &&
      other.disabled == disabled &&
      other.createdAt == createdAt &&
      other.link == link;

    @override
    int get hashCode =>
        code.hashCode +
        label.hashCode +
        maxUses.hashCode +
        used.hashCode +
        (perDay == null ? 0 : perDay.hashCode) +
        (startsAt == null ? 0 : startsAt.hashCode) +
        (expiresAt == null ? 0 : expiresAt.hashCode) +
        disabled.hashCode +
        createdAt.hashCode +
        link.hashCode;

  factory InviteCampaign.fromJson(Map<String, dynamic> json) => _$InviteCampaignFromJson(json);

  Map<String, dynamic> toJson() => _$InviteCampaignToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

