//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'decision_settings_uses_scan_gate.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class DecisionSettingsUsesScanGate {
  /// Returns a new [DecisionSettingsUsesScanGate] instance.
  DecisionSettingsUsesScanGate({

    required  this.mode,

    required  this.skipBelow,

    required  this.maxSkipsInRow,
  });

  @JsonKey(
    
    name: r'mode',
    required: true,
    includeIfNull: false,
  )


  final DecisionSettingsUsesScanGateModeEnum mode;



          // minimum: 0
          // maximum: 1
  @JsonKey(
    
    name: r'skip_below',
    required: true,
    includeIfNull: false,
  )


  final num skipBelow;



          // minimum: 1
          // maximum: 100
  @JsonKey(
    
    name: r'max_skips_in_row',
    required: true,
    includeIfNull: false,
  )


  final int maxSkipsInRow;





    @override
    bool operator ==(Object other) => identical(this, other) || other is DecisionSettingsUsesScanGate &&
      other.mode == mode &&
      other.skipBelow == skipBelow &&
      other.maxSkipsInRow == maxSkipsInRow;

    @override
    int get hashCode =>
        mode.hashCode +
        skipBelow.hashCode +
        maxSkipsInRow.hashCode;

  factory DecisionSettingsUsesScanGate.fromJson(Map<String, dynamic> json) => _$DecisionSettingsUsesScanGateFromJson(json);

  Map<String, dynamic> toJson() => _$DecisionSettingsUsesScanGateToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum DecisionSettingsUsesScanGateModeEnum {
@JsonValue(r'off')
off(r'off'),
@JsonValue(r'shadow')
shadow(r'shadow'),
@JsonValue(r'on')
on_(r'on');

const DecisionSettingsUsesScanGateModeEnum(this.value);

final String value;

@override
String toString() => value;
}


