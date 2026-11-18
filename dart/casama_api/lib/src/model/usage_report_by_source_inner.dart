//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/usage_source.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'usage_report_by_source_inner.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class UsageReportBySourceInner {
  /// Returns a new [UsageReportBySourceInner] instance.
  UsageReportBySourceInner({

    required  this.source_,

    required  this.costUsd,

    required  this.runs,
  });

  @JsonKey(
    
    name: r'source',
    required: true,
    includeIfNull: false,
  )


  final UsageSource source_;



  @JsonKey(
    
    name: r'cost_usd',
    required: true,
    includeIfNull: false,
  )


  final num costUsd;



  @JsonKey(
    
    name: r'runs',
    required: true,
    includeIfNull: false,
  )


  final int runs;





    @override
    bool operator ==(Object other) => identical(this, other) || other is UsageReportBySourceInner &&
      other.source_ == source_ &&
      other.costUsd == costUsd &&
      other.runs == runs;

    @override
    int get hashCode =>
        source_.hashCode +
        costUsd.hashCode +
        runs.hashCode;

  factory UsageReportBySourceInner.fromJson(Map<String, dynamic> json) => _$UsageReportBySourceInnerFromJson(json);

  Map<String, dynamic> toJson() => _$UsageReportBySourceInnerToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

