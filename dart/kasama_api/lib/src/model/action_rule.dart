//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:kasama_api/src/model/action_rule_target.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'action_rule.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ActionRule {
  /// Returns a new [ActionRule] instance.
  ActionRule({

    required  this.id,

    required  this.orgId,

    required  this.botId,

    required  this.matchKind,

    required  this.matchValue,

    required  this.target,

    required  this.rule,

    required  this.preview,

    required  this.createdAt,
  });

  @JsonKey(
    
    name: r'id',
    required: true,
    includeIfNull: false,
  )


  final String id;



  @JsonKey(
    
    name: r'org_id',
    required: true,
    includeIfNull: false,
  )


  final String orgId;



  @JsonKey(
    
    name: r'bot_id',
    required: true,
    includeIfNull: true,
  )


  final String? botId;



  @JsonKey(
    
    name: r'match_kind',
    required: true,
    includeIfNull: false,
  )


  final ActionRuleMatchKindEnum matchKind;



  @JsonKey(
    
    name: r'match_value',
    required: true,
    includeIfNull: false,
  )


  final String matchValue;



  @JsonKey(
    
    name: r'target',
    required: true,
    includeIfNull: true,
  )


  final ActionRuleTarget? target;



  @JsonKey(
    
    name: r'rule',
    required: true,
    includeIfNull: false,
  )


  final ActionRuleRuleEnum rule;



      /// In plain language, e.g. Sends messages to anyone at acme.com without asking
  @JsonKey(
    
    name: r'preview',
    required: true,
    includeIfNull: false,
  )


  final String preview;



  @JsonKey(
    
    name: r'created_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime createdAt;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ActionRule &&
      other.id == id &&
      other.orgId == orgId &&
      other.botId == botId &&
      other.matchKind == matchKind &&
      other.matchValue == matchValue &&
      other.target == target &&
      other.rule == rule &&
      other.preview == preview &&
      other.createdAt == createdAt;

    @override
    int get hashCode =>
        id.hashCode +
        orgId.hashCode +
        (botId == null ? 0 : botId.hashCode) +
        matchKind.hashCode +
        matchValue.hashCode +
        (target == null ? 0 : target.hashCode) +
        rule.hashCode +
        preview.hashCode +
        createdAt.hashCode;

  factory ActionRule.fromJson(Map<String, dynamic> json) => _$ActionRuleFromJson(json);

  Map<String, dynamic> toJson() => _$ActionRuleToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum ActionRuleMatchKindEnum {
@JsonValue(r'tool')
tool(r'tool'),
@JsonValue(r'group')
group(r'group'),
@JsonValue(r'category')
category(r'category');

const ActionRuleMatchKindEnum(this.value);

final String value;

@override
String toString() => value;
}



enum ActionRuleRuleEnum {
@JsonValue(r'allow')
allow(r'allow'),
@JsonValue(r'allow_within_limits')
allowWithinLimits(r'allow_within_limits'),
@JsonValue(r'ask')
ask(r'ask'),
@JsonValue(r'hand_off')
handOff(r'hand_off');

const ActionRuleRuleEnum(this.value);

final String value;

@override
String toString() => value;
}


