//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:kasama_api/src/model/usage_report_by_bot_inner.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'usage_report.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class UsageReport {
  /// Returns a new [UsageReport] instance.
  UsageReport({

    required  this.period,

    required  this.since,

    required  this.totalCostUsd,

    required  this.byBot,
  });

  @JsonKey(
    
    name: r'period',
    required: true,
    includeIfNull: false,
  )


  final UsageReportPeriodEnum period;



  @JsonKey(
    
    name: r'since',
    required: true,
    includeIfNull: false,
  )


  final DateTime since;



  @JsonKey(
    
    name: r'total_cost_usd',
    required: true,
    includeIfNull: false,
  )


  final num totalCostUsd;



  @JsonKey(
    
    name: r'by_bot',
    required: true,
    includeIfNull: false,
  )


  final List<UsageReportByBotInner> byBot;





    @override
    bool operator ==(Object other) => identical(this, other) || other is UsageReport &&
      other.period == period &&
      other.since == since &&
      other.totalCostUsd == totalCostUsd &&
      other.byBot == byBot;

    @override
    int get hashCode =>
        period.hashCode +
        since.hashCode +
        totalCostUsd.hashCode +
        byBot.hashCode;

  factory UsageReport.fromJson(Map<String, dynamic> json) => _$UsageReportFromJson(json);

  Map<String, dynamic> toJson() => _$UsageReportToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum UsageReportPeriodEnum {
@JsonValue(r'day')
day(r'day'),
@JsonValue(r'month')
month(r'month');

const UsageReportPeriodEnum(this.value);

final String value;

@override
String toString() => value;
}


