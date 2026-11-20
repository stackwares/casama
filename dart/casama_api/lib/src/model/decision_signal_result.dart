//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/decision_signal_result_thresholds_inner.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'decision_signal_result.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class DecisionSignalResult {
  /// Returns a new [DecisionSignalResult] instance.
  DecisionSignalResult({

    required  this.use,

    required  this.signal,

    required  this.model,

    required  this.rows,

    required  this.answered,

    required  this.errors,

    required  this.latencyP50Ms,

    required  this.latencyP95Ms,

    required  this.costUsd,

    required  this.labelled,

    required  this.positives,

    required  this.thresholds,
  });

  @JsonKey(
    
    name: r'use',
    required: true,
    includeIfNull: false,
  )


  final String use;



      /// What is measured, e.g. scan_gate or reply_check:memory
  @JsonKey(
    
    name: r'signal',
    required: true,
    includeIfNull: false,
  )


  final String signal;



  @JsonKey(
    
    name: r'model',
    required: true,
    includeIfNull: false,
  )


  final String model;



  @JsonKey(
    
    name: r'rows',
    required: true,
    includeIfNull: false,
  )


  final int rows;



  @JsonKey(
    
    name: r'answered',
    required: true,
    includeIfNull: false,
  )


  final int answered;



  @JsonKey(
    
    name: r'errors',
    required: true,
    includeIfNull: false,
  )


  final int errors;



  @JsonKey(
    
    name: r'latency_p50_ms',
    required: true,
    includeIfNull: false,
  )


  final num latencyP50Ms;



  @JsonKey(
    
    name: r'latency_p95_ms',
    required: true,
    includeIfNull: false,
  )


  final num latencyP95Ms;



  @JsonKey(
    
    name: r'cost_usd',
    required: true,
    includeIfNull: false,
  )


  final num costUsd;



  @JsonKey(
    
    name: r'labelled',
    required: true,
    includeIfNull: false,
  )


  final int labelled;



      /// Labelled rows where the thing happened (a find, a flag, an accept)
  @JsonKey(
    
    name: r'positives',
    required: true,
    includeIfNull: false,
  )


  final int positives;



  @JsonKey(
    
    name: r'thresholds',
    required: true,
    includeIfNull: false,
  )


  final List<DecisionSignalResultThresholdsInner> thresholds;





    @override
    bool operator ==(Object other) => identical(this, other) || other is DecisionSignalResult &&
      other.use == use &&
      other.signal == signal &&
      other.model == model &&
      other.rows == rows &&
      other.answered == answered &&
      other.errors == errors &&
      other.latencyP50Ms == latencyP50Ms &&
      other.latencyP95Ms == latencyP95Ms &&
      other.costUsd == costUsd &&
      other.labelled == labelled &&
      other.positives == positives &&
      other.thresholds == thresholds;

    @override
    int get hashCode =>
        use.hashCode +
        signal.hashCode +
        model.hashCode +
        rows.hashCode +
        answered.hashCode +
        errors.hashCode +
        latencyP50Ms.hashCode +
        latencyP95Ms.hashCode +
        costUsd.hashCode +
        labelled.hashCode +
        positives.hashCode +
        thresholds.hashCode;

  factory DecisionSignalResult.fromJson(Map<String, dynamic> json) => _$DecisionSignalResultFromJson(json);

  Map<String, dynamic> toJson() => _$DecisionSignalResultToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

