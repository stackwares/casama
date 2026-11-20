//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'decision_settings_uses_long_run.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class DecisionSettingsUsesLongRun {
  /// Returns a new [DecisionSettingsUsesLongRun] instance.
  DecisionSettingsUsesLongRun({

    required  this.mode,

    required  this.repeatingAbove,

    required  this.firstStep,

    required  this.every,
  });

  @JsonKey(
    
    name: r'mode',
    required: true,
    includeIfNull: false,
  )


  final DecisionSettingsUsesLongRunModeEnum mode;



          // minimum: 0
          // maximum: 1
  @JsonKey(
    
    name: r'repeating_above',
    required: true,
    includeIfNull: false,
  )


  final num repeatingAbove;



          // minimum: 1
          // maximum: 100
  @JsonKey(
    
    name: r'first_step',
    required: true,
    includeIfNull: false,
  )


  final int firstStep;



          // minimum: 1
          // maximum: 100
  @JsonKey(
    
    name: r'every',
    required: true,
    includeIfNull: false,
  )


  final int every;





    @override
    bool operator ==(Object other) => identical(this, other) || other is DecisionSettingsUsesLongRun &&
      other.mode == mode &&
      other.repeatingAbove == repeatingAbove &&
      other.firstStep == firstStep &&
      other.every == every;

    @override
    int get hashCode =>
        mode.hashCode +
        repeatingAbove.hashCode +
        firstStep.hashCode +
        every.hashCode;

  factory DecisionSettingsUsesLongRun.fromJson(Map<String, dynamic> json) => _$DecisionSettingsUsesLongRunFromJson(json);

  Map<String, dynamic> toJson() => _$DecisionSettingsUsesLongRunToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum DecisionSettingsUsesLongRunModeEnum {
@JsonValue(r'off')
off(r'off'),
@JsonValue(r'shadow')
shadow(r'shadow'),
@JsonValue(r'on')
on_(r'on');

const DecisionSettingsUsesLongRunModeEnum(this.value);

final String value;

@override
String toString() => value;
}


