//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'admin_overview.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminOverview {
  /// Returns a new [AdminOverview] instance.
  AdminOverview({

    required  this.version,

    required  this.users,

    required  this.orgs,

    required  this.bots,

    required  this.runs24h,

    required  this.failedRuns24h,

    required  this.cost24hUsd,

    required  this.computersRunning,

    required  this.devicesOnline,
  });

  @JsonKey(
    
    name: r'version',
    required: true,
    includeIfNull: false,
  )


  final String version;



  @JsonKey(
    
    name: r'users',
    required: true,
    includeIfNull: false,
  )


  final int users;



  @JsonKey(
    
    name: r'orgs',
    required: true,
    includeIfNull: false,
  )


  final int orgs;



  @JsonKey(
    
    name: r'bots',
    required: true,
    includeIfNull: false,
  )


  final int bots;



  @JsonKey(
    
    name: r'runs_24h',
    required: true,
    includeIfNull: false,
  )


  final int runs24h;



  @JsonKey(
    
    name: r'failed_runs_24h',
    required: true,
    includeIfNull: false,
  )


  final int failedRuns24h;



  @JsonKey(
    
    name: r'cost_24h_usd',
    required: true,
    includeIfNull: false,
  )


  final num cost24hUsd;



  @JsonKey(
    
    name: r'computers_running',
    required: true,
    includeIfNull: false,
  )


  final int computersRunning;



  @JsonKey(
    
    name: r'devices_online',
    required: true,
    includeIfNull: false,
  )


  final int devicesOnline;





    @override
    bool operator ==(Object other) => identical(this, other) || other is AdminOverview &&
      other.version == version &&
      other.users == users &&
      other.orgs == orgs &&
      other.bots == bots &&
      other.runs24h == runs24h &&
      other.failedRuns24h == failedRuns24h &&
      other.cost24hUsd == cost24hUsd &&
      other.computersRunning == computersRunning &&
      other.devicesOnline == devicesOnline;

    @override
    int get hashCode =>
        version.hashCode +
        users.hashCode +
        orgs.hashCode +
        bots.hashCode +
        runs24h.hashCode +
        failedRuns24h.hashCode +
        cost24hUsd.hashCode +
        computersRunning.hashCode +
        devicesOnline.hashCode;

  factory AdminOverview.fromJson(Map<String, dynamic> json) => _$AdminOverviewFromJson(json);

  Map<String, dynamic> toJson() => _$AdminOverviewToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

