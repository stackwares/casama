//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/action_rule_target.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'create_action_rule_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CreateActionRuleRequest {
  /// Returns a new [CreateActionRuleRequest] instance.
  CreateActionRuleRequest({

    required  this.orgId,

     this.botId,

    required  this.matchKind,

    required  this.matchValue,

     this.target,

    required  this.rule,
  });

  @JsonKey(
    
    name: r'org_id',
    required: true,
    includeIfNull: false,
  )


  final String orgId;



      /// Null or missing: the whole workspace (admins)
  @JsonKey(
    
    name: r'bot_id',
    required: false,
    includeIfNull: false,
  )


  final String? botId;



  @JsonKey(
    
    name: r'match_kind',
    required: true,
    includeIfNull: false,
  )


  final CreateActionRuleRequestMatchKindEnum matchKind;



  @JsonKey(
    
    name: r'match_value',
    required: true,
    includeIfNull: false,
  )


  final String matchValue;



  @JsonKey(
    
    name: r'target',
    required: false,
    includeIfNull: false,
  )


  final ActionRuleTarget? target;



  @JsonKey(
    
    name: r'rule',
    required: true,
    includeIfNull: false,
  )


  final CreateActionRuleRequestRuleEnum rule;





    @override
    bool operator ==(Object other) => identical(this, other) || other is CreateActionRuleRequest &&
      other.orgId == orgId &&
      other.botId == botId &&
      other.matchKind == matchKind &&
      other.matchValue == matchValue &&
      other.target == target &&
      other.rule == rule;

    @override
    int get hashCode =>
        orgId.hashCode +
        (botId == null ? 0 : botId.hashCode) +
        matchKind.hashCode +
        matchValue.hashCode +
        (target == null ? 0 : target.hashCode) +
        rule.hashCode;

  factory CreateActionRuleRequest.fromJson(Map<String, dynamic> json) => _$CreateActionRuleRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CreateActionRuleRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum CreateActionRuleRequestMatchKindEnum {
@JsonValue(r'tool')
tool(r'tool'),
@JsonValue(r'group')
group(r'group'),
@JsonValue(r'category')
category(r'category');

const CreateActionRuleRequestMatchKindEnum(this.value);

final String value;

@override
String toString() => value;
}



enum CreateActionRuleRequestRuleEnum {
@JsonValue(r'allow')
allow(r'allow'),
@JsonValue(r'allow_within_limits')
allowWithinLimits(r'allow_within_limits'),
@JsonValue(r'ask')
ask(r'ask'),
@JsonValue(r'hand_off')
handOff(r'hand_off');

const CreateActionRuleRequestRuleEnum(this.value);

final String value;

@override
String toString() => value;
}


