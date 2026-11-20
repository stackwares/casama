//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'decision_signal_result_thresholds_inner.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class DecisionSignalResultThresholdsInner {
  /// Returns a new [DecisionSignalResultThresholdsInner] instance.
  DecisionSignalResultThresholdsInner({

    required  this.threshold,

    required  this.acted,

    required  this.actedPositive,

    required  this.actedNegative,

    required  this.actedSevere,
  });

  @JsonKey(
    
    name: r'threshold',
    required: true,
    includeIfNull: false,
  )


  final num threshold;



      /// Answered rows the code would act on
  @JsonKey(
    
    name: r'acted',
    required: true,
    includeIfNull: false,
  )


  final int acted;



  @JsonKey(
    
    name: r'acted_positive',
    required: true,
    includeIfNull: false,
  )


  final int actedPositive;



  @JsonKey(
    
    name: r'acted_negative',
    required: true,
    includeIfNull: false,
  )


  final int actedNegative;



      /// scan_gate: skipped scans whose suggestion was accepted
  @JsonKey(
    
    name: r'acted_severe',
    required: true,
    includeIfNull: false,
  )


  final int actedSevere;





    @override
    bool operator ==(Object other) => identical(this, other) || other is DecisionSignalResultThresholdsInner &&
      other.threshold == threshold &&
      other.acted == acted &&
      other.actedPositive == actedPositive &&
      other.actedNegative == actedNegative &&
      other.actedSevere == actedSevere;

    @override
    int get hashCode =>
        threshold.hashCode +
        acted.hashCode +
        actedPositive.hashCode +
        actedNegative.hashCode +
        actedSevere.hashCode;

  factory DecisionSignalResultThresholdsInner.fromJson(Map<String, dynamic> json) => _$DecisionSignalResultThresholdsInnerFromJson(json);

  Map<String, dynamic> toJson() => _$DecisionSignalResultThresholdsInnerToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

