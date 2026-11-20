//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/decision_settings_uses_reply_check.dart';
import 'package:casama_api/src/model/decision_settings_uses_tool_gate.dart';
import 'package:casama_api/src/model/decision_settings_uses_effort.dart';
import 'package:casama_api/src/model/decision_settings_uses_long_run.dart';
import 'package:casama_api/src/model/decision_settings_uses_push_score.dart';
import 'package:casama_api/src/model/decision_settings_uses_watcher_gate.dart';
import 'package:casama_api/src/model/decision_settings_uses_scan_gate.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'decision_settings_uses.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class DecisionSettingsUses {
  /// Returns a new [DecisionSettingsUses] instance.
  DecisionSettingsUses({

    required  this.scanGate,

    required  this.replyCheck,

    required  this.pushScore,

    required  this.toolGate,

    required  this.longRun,

    required  this.effort,

    required  this.watcherGate,
  });

  @JsonKey(
    
    name: r'scan_gate',
    required: true,
    includeIfNull: false,
  )


  final DecisionSettingsUsesScanGate scanGate;



  @JsonKey(
    
    name: r'reply_check',
    required: true,
    includeIfNull: false,
  )


  final DecisionSettingsUsesReplyCheck replyCheck;



  @JsonKey(
    
    name: r'push_score',
    required: true,
    includeIfNull: false,
  )


  final DecisionSettingsUsesPushScore pushScore;



  @JsonKey(
    
    name: r'tool_gate',
    required: true,
    includeIfNull: false,
  )


  final DecisionSettingsUsesToolGate toolGate;



  @JsonKey(
    
    name: r'long_run',
    required: true,
    includeIfNull: false,
  )


  final DecisionSettingsUsesLongRun longRun;



  @JsonKey(
    
    name: r'effort',
    required: true,
    includeIfNull: false,
  )


  final DecisionSettingsUsesEffort effort;



  @JsonKey(
    
    name: r'watcher_gate',
    required: true,
    includeIfNull: false,
  )


  final DecisionSettingsUsesWatcherGate watcherGate;





    @override
    bool operator ==(Object other) => identical(this, other) || other is DecisionSettingsUses &&
      other.scanGate == scanGate &&
      other.replyCheck == replyCheck &&
      other.pushScore == pushScore &&
      other.toolGate == toolGate &&
      other.longRun == longRun &&
      other.effort == effort &&
      other.watcherGate == watcherGate;

    @override
    int get hashCode =>
        scanGate.hashCode +
        replyCheck.hashCode +
        pushScore.hashCode +
        toolGate.hashCode +
        longRun.hashCode +
        effort.hashCode +
        watcherGate.hashCode;

  factory DecisionSettingsUses.fromJson(Map<String, dynamic> json) => _$DecisionSettingsUsesFromJson(json);

  Map<String, dynamic> toJson() => _$DecisionSettingsUsesToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

