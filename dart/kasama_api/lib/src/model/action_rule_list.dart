//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:kasama_api/src/model/action_rule.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'action_rule_list.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ActionRuleList {
  /// Returns a new [ActionRuleList] instance.
  ActionRuleList({

    required  this.items,
  });

  @JsonKey(
    
    name: r'items',
    required: true,
    includeIfNull: false,
  )


  final List<ActionRule> items;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ActionRuleList &&
      other.items == items;

    @override
    int get hashCode =>
        items.hashCode;

  factory ActionRuleList.fromJson(Map<String, dynamic> json) => _$ActionRuleListFromJson(json);

  Map<String, dynamic> toJson() => _$ActionRuleListToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

