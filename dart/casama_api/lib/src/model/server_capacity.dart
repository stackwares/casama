//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/server_capacity_latest.dart';
import 'package:casama_api/src/model/server_capacity_days_inner.dart';
import 'package:casama_api/src/model/server_capacity_alerts_inner.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'server_capacity.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ServerCapacity {
  /// Returns a new [ServerCapacity] instance.
  ServerCapacity({

    required  this.budgetMb,

    required  this.latest,

    required  this.days,

    required  this.refusals30d,

    required  this.fullInWeeks,

    required  this.alerts,
  });

      /// Memory hosted computers may use (COMPUTER_HOST_MEMORY_GB); 0 = none set
  @JsonKey(
    
    name: r'budget_mb',
    required: true,
    includeIfNull: false,
  )


  final int budgetMb;



  @JsonKey(
    
    name: r'latest',
    required: true,
    includeIfNull: true,
  )


  final ServerCapacityLatest? latest;



  @JsonKey(
    
    name: r'days',
    required: true,
    includeIfNull: false,
  )


  final List<ServerCapacityDaysInner> days;



  @JsonKey(
    
    name: r'refusals_30d',
    required: true,
    includeIfNull: false,
  )


  final int refusals30d;



      /// Weeks until daily peaks reach the budget at the 30-day trend
  @JsonKey(
    
    name: r'full_in_weeks',
    required: true,
    includeIfNull: true,
  )


  final num? fullInWeeks;



  @JsonKey(
    
    name: r'alerts',
    required: true,
    includeIfNull: false,
  )


  final List<ServerCapacityAlertsInner> alerts;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ServerCapacity &&
      other.budgetMb == budgetMb &&
      other.latest == latest &&
      other.days == days &&
      other.refusals30d == refusals30d &&
      other.fullInWeeks == fullInWeeks &&
      other.alerts == alerts;

    @override
    int get hashCode =>
        budgetMb.hashCode +
        (latest == null ? 0 : latest.hashCode) +
        days.hashCode +
        refusals30d.hashCode +
        (fullInWeeks == null ? 0 : fullInWeeks.hashCode) +
        alerts.hashCode;

  factory ServerCapacity.fromJson(Map<String, dynamic> json) => _$ServerCapacityFromJson(json);

  Map<String, dynamic> toJson() => _$ServerCapacityToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

