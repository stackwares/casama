//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'decision_settings_uses_reply_check.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class DecisionSettingsUsesReplyCheck {
  /// Returns a new [DecisionSettingsUsesReplyCheck] instance.
  DecisionSettingsUsesReplyCheck({

    required  this.mode,

    required  this.flagAbove,

    required  this.memorySkipBelow,

    required  this.correctionAbove,
  });

  @JsonKey(
    
    name: r'mode',
    required: true,
    includeIfNull: false,
  )


  final DecisionSettingsUsesReplyCheckModeEnum mode;



          // minimum: 0
          // maximum: 1
  @JsonKey(
    
    name: r'flag_above',
    required: true,
    includeIfNull: false,
  )


  final num flagAbove;



          // minimum: 0
          // maximum: 1
  @JsonKey(
    
    name: r'memory_skip_below',
    required: true,
    includeIfNull: false,
  )


  final num memorySkipBelow;



          // minimum: 0
          // maximum: 1
  @JsonKey(
    
    name: r'correction_above',
    required: true,
    includeIfNull: false,
  )


  final num correctionAbove;





    @override
    bool operator ==(Object other) => identical(this, other) || other is DecisionSettingsUsesReplyCheck &&
      other.mode == mode &&
      other.flagAbove == flagAbove &&
      other.memorySkipBelow == memorySkipBelow &&
      other.correctionAbove == correctionAbove;

    @override
    int get hashCode =>
        mode.hashCode +
        flagAbove.hashCode +
        memorySkipBelow.hashCode +
        correctionAbove.hashCode;

  factory DecisionSettingsUsesReplyCheck.fromJson(Map<String, dynamic> json) => _$DecisionSettingsUsesReplyCheckFromJson(json);

  Map<String, dynamic> toJson() => _$DecisionSettingsUsesReplyCheckToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum DecisionSettingsUsesReplyCheckModeEnum {
@JsonValue(r'off')
off(r'off'),
@JsonValue(r'shadow')
shadow(r'shadow'),
@JsonValue(r'on')
on_(r'on');

const DecisionSettingsUsesReplyCheckModeEnum(this.value);

final String value;

@override
String toString() => value;
}


