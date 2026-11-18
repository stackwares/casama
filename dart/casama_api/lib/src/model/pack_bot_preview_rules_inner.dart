//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'pack_bot_preview_rules_inner.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PackBotPreviewRulesInner {
  /// Returns a new [PackBotPreviewRulesInner] instance.
  PackBotPreviewRulesInner({

    required  this.matchKind,

    required  this.matchValue,

    required  this.rule,
  });

  @JsonKey(
    
    name: r'match_kind',
    required: true,
    includeIfNull: false,
  )


  final PackBotPreviewRulesInnerMatchKindEnum matchKind;



  @JsonKey(
    
    name: r'match_value',
    required: true,
    includeIfNull: false,
  )


  final String matchValue;



  @JsonKey(
    
    name: r'rule',
    required: true,
    includeIfNull: false,
  )


  final PackBotPreviewRulesInnerRuleEnum rule;





    @override
    bool operator ==(Object other) => identical(this, other) || other is PackBotPreviewRulesInner &&
      other.matchKind == matchKind &&
      other.matchValue == matchValue &&
      other.rule == rule;

    @override
    int get hashCode =>
        matchKind.hashCode +
        matchValue.hashCode +
        rule.hashCode;

  factory PackBotPreviewRulesInner.fromJson(Map<String, dynamic> json) => _$PackBotPreviewRulesInnerFromJson(json);

  Map<String, dynamic> toJson() => _$PackBotPreviewRulesInnerToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum PackBotPreviewRulesInnerMatchKindEnum {
@JsonValue(r'tool')
tool(r'tool'),
@JsonValue(r'group')
group(r'group'),
@JsonValue(r'category')
category(r'category');

const PackBotPreviewRulesInnerMatchKindEnum(this.value);

final String value;

@override
String toString() => value;
}



enum PackBotPreviewRulesInnerRuleEnum {
@JsonValue(r'ask')
ask(r'ask'),
@JsonValue(r'hand_off')
handOff(r'hand_off');

const PackBotPreviewRulesInnerRuleEnum(this.value);

final String value;

@override
String toString() => value;
}


