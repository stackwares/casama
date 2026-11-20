//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'billing_summary_computer_hours.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class BillingSummaryComputerHours {
  /// Returns a new [BillingSummaryComputerHours] instance.
  BillingSummaryComputerHours({

    required  this.usedHours,

    required  this.limitHours,

    required  this.resetsAt,
  });

      /// Hosted computer hours used this month (UTC)
  @JsonKey(
    
    name: r'used_hours',
    required: true,
    includeIfNull: false,
  )


  final num usedHours;



      /// The plan's computer hours a month
  @JsonKey(
    
    name: r'limit_hours',
    required: true,
    includeIfNull: false,
  )


  final num limitHours;



      /// The first of next month (UTC), when the hours reset
  @JsonKey(
    
    name: r'resets_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime resetsAt;





    @override
    bool operator ==(Object other) => identical(this, other) || other is BillingSummaryComputerHours &&
      other.usedHours == usedHours &&
      other.limitHours == limitHours &&
      other.resetsAt == resetsAt;

    @override
    int get hashCode =>
        usedHours.hashCode +
        limitHours.hashCode +
        resetsAt.hashCode;

  factory BillingSummaryComputerHours.fromJson(Map<String, dynamic> json) => _$BillingSummaryComputerHoursFromJson(json);

  Map<String, dynamic> toJson() => _$BillingSummaryComputerHoursToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

