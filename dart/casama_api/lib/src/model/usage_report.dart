//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/usage_report_by_day_inner.dart';
import 'package:casama_api/src/model/usage_report_by_person_inner.dart';
import 'package:casama_api/src/model/usage_report_by_bot_inner.dart';
import 'package:casama_api/src/model/usage_report_by_model_inner.dart';
import 'package:casama_api/src/model/usage_report_by_kind_inner.dart';
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

     this.byDay,

     this.byModel,

     this.byKind,

     this.runs,

     this.byPerson,

     this.waivedUsd,
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



  @JsonKey(
    
    name: r'by_day',
    required: false,
    includeIfNull: false,
  )


  final List<UsageReportByDayInner>? byDay;



  @JsonKey(
    
    name: r'by_model',
    required: false,
    includeIfNull: false,
  )


  final List<UsageReportByModelInner>? byModel;



  @JsonKey(
    
    name: r'by_kind',
    required: false,
    includeIfNull: false,
  )


  final List<UsageReportByKindInner>? byKind;



  @JsonKey(
    
    name: r'runs',
    required: false,
    includeIfNull: false,
  )


  final int? runs;



  @JsonKey(
    
    name: r'by_person',
    required: false,
    includeIfNull: false,
  )


  final List<UsageReportByPersonInner>? byPerson;



  @JsonKey(
    
    name: r'waived_usd',
    required: false,
    includeIfNull: false,
  )


  final num? waivedUsd;





    @override
    bool operator ==(Object other) => identical(this, other) || other is UsageReport &&
      other.period == period &&
      other.since == since &&
      other.totalCostUsd == totalCostUsd &&
      other.byBot == byBot &&
      other.byDay == byDay &&
      other.byModel == byModel &&
      other.byKind == byKind &&
      other.runs == runs &&
      other.byPerson == byPerson &&
      other.waivedUsd == waivedUsd;

    @override
    int get hashCode =>
        period.hashCode +
        since.hashCode +
        totalCostUsd.hashCode +
        byBot.hashCode +
        byDay.hashCode +
        byModel.hashCode +
        byKind.hashCode +
        runs.hashCode +
        byPerson.hashCode +
        waivedUsd.hashCode;

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
@JsonValue(r'week')
week(r'week'),
@JsonValue(r'month')
month(r'month'),
@JsonValue(r'year')
year(r'year');

const UsageReportPeriodEnum(this.value);

final String value;

@override
String toString() => value;
}


