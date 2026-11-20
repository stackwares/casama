//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'decision_settings_uses_watcher_gate.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class DecisionSettingsUsesWatcherGate {
  /// Returns a new [DecisionSettingsUsesWatcherGate] instance.
  DecisionSettingsUsesWatcherGate({

    required  this.mode,

    required  this.skipBelow,
  });

  @JsonKey(
    
    name: r'mode',
    required: true,
    includeIfNull: false,
  )


  final DecisionSettingsUsesWatcherGateModeEnum mode;



          // minimum: 0
          // maximum: 1
  @JsonKey(
    
    name: r'skip_below',
    required: true,
    includeIfNull: false,
  )


  final num skipBelow;





    @override
    bool operator ==(Object other) => identical(this, other) || other is DecisionSettingsUsesWatcherGate &&
      other.mode == mode &&
      other.skipBelow == skipBelow;

    @override
    int get hashCode =>
        mode.hashCode +
        skipBelow.hashCode;

  factory DecisionSettingsUsesWatcherGate.fromJson(Map<String, dynamic> json) => _$DecisionSettingsUsesWatcherGateFromJson(json);

  Map<String, dynamic> toJson() => _$DecisionSettingsUsesWatcherGateToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum DecisionSettingsUsesWatcherGateModeEnum {
@JsonValue(r'off')
off(r'off'),
@JsonValue(r'shadow')
shadow(r'shadow'),
@JsonValue(r'on')
on_(r'on');

const DecisionSettingsUsesWatcherGateModeEnum(this.value);

final String value;

@override
String toString() => value;
}


