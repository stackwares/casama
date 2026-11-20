//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/decision_settings_uses.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'decision_settings.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class DecisionSettings {
  /// Returns a new [DecisionSettings] instance.
  DecisionSettings({

    required  this.model,

    required  this.shadowModels,

    required  this.timeoutMs,

    required  this.uses,
  });

      /// OpenRouter decision model for uses that are on (pinned, e.g. typesafe/jev-1.14). Empty: nothing acts.
  @JsonKey(
    
    name: r'model',
    required: true,
    includeIfNull: false,
  )


  final String model;



  @JsonKey(
    
    name: r'shadow_models',
    required: true,
    includeIfNull: false,
  )


  final List<String> shadowModels;



          // minimum: 200
          // maximum: 5000
  @JsonKey(
    
    name: r'timeout_ms',
    required: true,
    includeIfNull: false,
  )


  final int timeoutMs;



  @JsonKey(
    
    name: r'uses',
    required: true,
    includeIfNull: false,
  )


  final DecisionSettingsUses uses;





    @override
    bool operator ==(Object other) => identical(this, other) || other is DecisionSettings &&
      other.model == model &&
      other.shadowModels == shadowModels &&
      other.timeoutMs == timeoutMs &&
      other.uses == uses;

    @override
    int get hashCode =>
        model.hashCode +
        shadowModels.hashCode +
        timeoutMs.hashCode +
        uses.hashCode;

  factory DecisionSettings.fromJson(Map<String, dynamic> json) => _$DecisionSettingsFromJson(json);

  Map<String, dynamic> toJson() => _$DecisionSettingsToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

