//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'usage_report_by_day_inner.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class UsageReportByDayInner {
  /// Returns a new [UsageReportByDayInner] instance.
  UsageReportByDayInner({

    required  this.day,

    required  this.costUsd,

    required  this.tokensIn,

    required  this.tokensOut,
  });

  @JsonKey(
    
    name: r'day',
    required: true,
    includeIfNull: false,
  )


  final String day;



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
    bool operator ==(Object other) => identical(this, other) || other is UsageReportByDayInner &&
      other.day == day &&
      other.costUsd == costUsd &&
      other.tokensIn == tokensIn &&
      other.tokensOut == tokensOut;

    @override
    int get hashCode =>
        day.hashCode +
        costUsd.hashCode +
        tokensIn.hashCode +
        tokensOut.hashCode;

  factory UsageReportByDayInner.fromJson(Map<String, dynamic> json) => _$UsageReportByDayInnerFromJson(json);

  Map<String, dynamic> toJson() => _$UsageReportByDayInnerToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

