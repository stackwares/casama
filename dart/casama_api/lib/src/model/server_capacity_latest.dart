//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'server_capacity_latest.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ServerCapacityLatest {
  /// Returns a new [ServerCapacityLatest] instance.
  ServerCapacityLatest({

    required  this.at,

    required  this.memTotalMb,

    required  this.memAvailableMb,

    required  this.load1,

    required  this.cpus,

    required  this.diskUsedPct,

    required  this.computersRunning,

    required  this.computersMemMb,
  });

  @JsonKey(
    
    name: r'at',
    required: true,
    includeIfNull: false,
  )


  final String at;



  @JsonKey(
    
    name: r'mem_total_mb',
    required: true,
    includeIfNull: false,
  )


  final int memTotalMb;



  @JsonKey(
    
    name: r'mem_available_mb',
    required: true,
    includeIfNull: false,
  )


  final int memAvailableMb;



  @JsonKey(
    
    name: r'load1',
    required: true,
    includeIfNull: false,
  )


  final num load1;



  @JsonKey(
    
    name: r'cpus',
    required: true,
    includeIfNull: false,
  )


  final int cpus;



  @JsonKey(
    
    name: r'disk_used_pct',
    required: true,
    includeIfNull: true,
  )


  final num? diskUsedPct;



  @JsonKey(
    
    name: r'computers_running',
    required: true,
    includeIfNull: false,
  )


  final int computersRunning;



  @JsonKey(
    
    name: r'computers_mem_mb',
    required: true,
    includeIfNull: false,
  )


  final int computersMemMb;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ServerCapacityLatest &&
      other.at == at &&
      other.memTotalMb == memTotalMb &&
      other.memAvailableMb == memAvailableMb &&
      other.load1 == load1 &&
      other.cpus == cpus &&
      other.diskUsedPct == diskUsedPct &&
      other.computersRunning == computersRunning &&
      other.computersMemMb == computersMemMb;

    @override
    int get hashCode =>
        at.hashCode +
        memTotalMb.hashCode +
        memAvailableMb.hashCode +
        load1.hashCode +
        cpus.hashCode +
        (diskUsedPct == null ? 0 : diskUsedPct.hashCode) +
        computersRunning.hashCode +
        computersMemMb.hashCode;

  factory ServerCapacityLatest.fromJson(Map<String, dynamic> json) => _$ServerCapacityLatestFromJson(json);

  Map<String, dynamic> toJson() => _$ServerCapacityLatestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

