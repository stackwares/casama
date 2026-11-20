//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'decision_settings_uses_tool_gate.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class DecisionSettingsUsesToolGate {
  /// Returns a new [DecisionSettingsUsesToolGate] instance.
  DecisionSettingsUsesToolGate({

    required  this.mode,

    required  this.askBelow,
  });

  @JsonKey(
    
    name: r'mode',
    required: true,
    includeIfNull: false,
  )


  final DecisionSettingsUsesToolGateModeEnum mode;



          // minimum: 0
          // maximum: 1
  @JsonKey(
    
    name: r'ask_below',
    required: true,
    includeIfNull: false,
  )


  final num askBelow;





    @override
    bool operator ==(Object other) => identical(this, other) || other is DecisionSettingsUsesToolGate &&
      other.mode == mode &&
      other.askBelow == askBelow;

    @override
    int get hashCode =>
        mode.hashCode +
        askBelow.hashCode;

  factory DecisionSettingsUsesToolGate.fromJson(Map<String, dynamic> json) => _$DecisionSettingsUsesToolGateFromJson(json);

  Map<String, dynamic> toJson() => _$DecisionSettingsUsesToolGateToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum DecisionSettingsUsesToolGateModeEnum {
@JsonValue(r'off')
off(r'off'),
@JsonValue(r'shadow')
shadow(r'shadow'),
@JsonValue(r'on')
on_(r'on');

const DecisionSettingsUsesToolGateModeEnum(this.value);

final String value;

@override
String toString() => value;
}


