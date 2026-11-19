//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/invite_campaign.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'invite_campaign_list.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class InviteCampaignList {
  /// Returns a new [InviteCampaignList] instance.
  InviteCampaignList({

    required  this.items,
  });

  @JsonKey(
    
    name: r'items',
    required: true,
    includeIfNull: false,
  )


  final List<InviteCampaign> items;





    @override
    bool operator ==(Object other) => identical(this, other) || other is InviteCampaignList &&
      other.items == items;

    @override
    int get hashCode =>
        items.hashCode;

  factory InviteCampaignList.fromJson(Map<String, dynamic> json) => _$InviteCampaignListFromJson(json);

  Map<String, dynamic> toJson() => _$InviteCampaignListToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

