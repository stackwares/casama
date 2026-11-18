//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/computer_usage_day.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'computer_usage.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ComputerUsage {
  /// Returns a new [ComputerUsage] instance.
  ComputerUsage({

    required  this.monthStart,

    required  this.seconds,

    required  this.costUsd,

    required  this.days,
  });

  @JsonKey(
    
    name: r'month_start',
    required: true,
    includeIfNull: false,
  )


  final String monthStart;



  @JsonKey(
    
    name: r'seconds',
    required: true,
    includeIfNull: false,
  )


  final int seconds;



  @JsonKey(
    
    name: r'cost_usd',
    required: true,
    includeIfNull: false,
  )


  final num costUsd;



  @JsonKey(
    
    name: r'days',
    required: true,
    includeIfNull: false,
  )


  final List<ComputerUsageDay> days;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ComputerUsage &&
      other.monthStart == monthStart &&
      other.seconds == seconds &&
      other.costUsd == costUsd &&
      other.days == days;

    @override
    int get hashCode =>
        monthStart.hashCode +
        seconds.hashCode +
        costUsd.hashCode +
        days.hashCode;

  factory ComputerUsage.fromJson(Map<String, dynamic> json) => _$ComputerUsageFromJson(json);

  Map<String, dynamic> toJson() => _$ComputerUsageToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

