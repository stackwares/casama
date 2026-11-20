//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'decision_settings_uses_effort.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class DecisionSettingsUsesEffort {
  /// Returns a new [DecisionSettingsUsesEffort] instance.
  DecisionSettingsUsesEffort({

    required  this.mode,

    required  this.quickAbove,
  });

  @JsonKey(
    
    name: r'mode',
    required: true,
    includeIfNull: false,
  )


  final DecisionSettingsUsesEffortModeEnum mode;



          // minimum: 0
          // maximum: 1
  @JsonKey(
    
    name: r'quick_above',
    required: true,
    includeIfNull: false,
  )


  final num quickAbove;





    @override
    bool operator ==(Object other) => identical(this, other) || other is DecisionSettingsUsesEffort &&
      other.mode == mode &&
      other.quickAbove == quickAbove;

    @override
    int get hashCode =>
        mode.hashCode +
        quickAbove.hashCode;

  factory DecisionSettingsUsesEffort.fromJson(Map<String, dynamic> json) => _$DecisionSettingsUsesEffortFromJson(json);

  Map<String, dynamic> toJson() => _$DecisionSettingsUsesEffortToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum DecisionSettingsUsesEffortModeEnum {
@JsonValue(r'off')
off(r'off'),
@JsonValue(r'shadow')
shadow(r'shadow'),
@JsonValue(r'on')
on_(r'on');

const DecisionSettingsUsesEffortModeEnum(this.value);

final String value;

@override
String toString() => value;
}


