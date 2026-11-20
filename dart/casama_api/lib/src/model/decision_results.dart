//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/decision_signal_result.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'decision_results.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class DecisionResults {
  /// Returns a new [DecisionResults] instance.
  DecisionResults({

    required  this.days,

    required  this.items,
  });

  @JsonKey(
    
    name: r'days',
    required: true,
    includeIfNull: false,
  )


  final int days;



  @JsonKey(
    
    name: r'items',
    required: true,
    includeIfNull: false,
  )


  final List<DecisionSignalResult> items;





    @override
    bool operator ==(Object other) => identical(this, other) || other is DecisionResults &&
      other.days == days &&
      other.items == items;

    @override
    int get hashCode =>
        days.hashCode +
        items.hashCode;

  factory DecisionResults.fromJson(Map<String, dynamic> json) => _$DecisionResultsFromJson(json);

  Map<String, dynamic> toJson() => _$DecisionResultsToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

