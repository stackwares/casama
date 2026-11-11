//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'usage_report_by_model_inner.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class UsageReportByModelInner {
  /// Returns a new [UsageReportByModelInner] instance.
  UsageReportByModelInner({

    required  this.model,

    required  this.costUsd,

    required  this.tokensIn,

    required  this.tokensOut,
  });

  @JsonKey(
    
    name: r'model',
    required: true,
    includeIfNull: true,
  )


  final String? model;



  @JsonKey(
    
    name: r'cost_usd',
    required: true,
    includeIfNull: false,
  )


  final num costUsd;



  @JsonKey(
    
    name: r'tokens_in',
    required: true,
    includeIfNull: false,
  )


  final int tokensIn;



  @JsonKey(
    
    name: r'tokens_out',
    required: true,
    includeIfNull: false,
  )


  final int tokensOut;





    @override
    bool operator ==(Object other) => identical(this, other) || other is UsageReportByModelInner &&
      other.model == model &&
      other.costUsd == costUsd &&
      other.tokensIn == tokensIn &&
      other.tokensOut == tokensOut;

    @override
    int get hashCode =>
        (model == null ? 0 : model.hashCode) +
        costUsd.hashCode +
        tokensIn.hashCode +
        tokensOut.hashCode;

  factory UsageReportByModelInner.fromJson(Map<String, dynamic> json) => _$UsageReportByModelInnerFromJson(json);

  Map<String, dynamic> toJson() => _$UsageReportByModelInnerToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

