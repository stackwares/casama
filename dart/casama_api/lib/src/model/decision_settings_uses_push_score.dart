//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'decision_settings_uses_push_score.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class DecisionSettingsUsesPushScore {
  /// Returns a new [DecisionSettingsUsesPushScore] instance.
  DecisionSettingsUsesPushScore({

    required  this.mode,

    required  this.holdBelow,
  });

  @JsonKey(
    
    name: r'mode',
    required: true,
    includeIfNull: false,
  )


  final DecisionSettingsUsesPushScoreModeEnum mode;



          // minimum: 0
          // maximum: 1
  @JsonKey(
    
    name: r'hold_below',
    required: true,
    includeIfNull: false,
  )


  final num holdBelow;





    @override
    bool operator ==(Object other) => identical(this, other) || other is DecisionSettingsUsesPushScore &&
      other.mode == mode &&
      other.holdBelow == holdBelow;

    @override
    int get hashCode =>
        mode.hashCode +
        holdBelow.hashCode;

  factory DecisionSettingsUsesPushScore.fromJson(Map<String, dynamic> json) => _$DecisionSettingsUsesPushScoreFromJson(json);

  Map<String, dynamic> toJson() => _$DecisionSettingsUsesPushScoreToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum DecisionSettingsUsesPushScoreModeEnum {
@JsonValue(r'off')
off(r'off'),
@JsonValue(r'shadow')
shadow(r'shadow'),
@JsonValue(r'on')
on_(r'on');

const DecisionSettingsUsesPushScoreModeEnum(this.value);

final String value;

@override
String toString() => value;
}


