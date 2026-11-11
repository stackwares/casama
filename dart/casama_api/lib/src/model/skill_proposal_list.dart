//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/skill_proposal.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'skill_proposal_list.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SkillProposalList {
  /// Returns a new [SkillProposalList] instance.
  SkillProposalList({

    required  this.items,
  });

  @JsonKey(
    
    name: r'items',
    required: true,
    includeIfNull: false,
  )


  final List<SkillProposal> items;





    @override
    bool operator ==(Object other) => identical(this, other) || other is SkillProposalList &&
      other.items == items;

    @override
    int get hashCode =>
        items.hashCode;

  factory SkillProposalList.fromJson(Map<String, dynamic> json) => _$SkillProposalListFromJson(json);

  Map<String, dynamic> toJson() => _$SkillProposalListToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

