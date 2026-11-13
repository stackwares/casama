//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'usage_report_by_person_inner.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class UsageReportByPersonInner {
  /// Returns a new [UsageReportByPersonInner] instance.
  UsageReportByPersonInner({

    required  this.userId,

    required  this.name,

    required  this.costUsd,

    required  this.runs,
  });

  @JsonKey(
    
    name: r'user_id',
    required: true,
    includeIfNull: true,
  )


  final String? userId;



  @JsonKey(
    
    name: r'name',
    required: true,
    includeIfNull: true,
  )


  final String? name;



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
    bool operator ==(Object other) => identical(this, other) || other is UsageReportByPersonInner &&
      other.userId == userId &&
      other.name == name &&
      other.costUsd == costUsd &&
      other.runs == runs;

    @override
    int get hashCode =>
        (userId == null ? 0 : userId.hashCode) +
        (name == null ? 0 : name.hashCode) +
        costUsd.hashCode +
        runs.hashCode;

  factory UsageReportByPersonInner.fromJson(Map<String, dynamic> json) => _$UsageReportByPersonInnerFromJson(json);

  Map<String, dynamic> toJson() => _$UsageReportByPersonInnerToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

