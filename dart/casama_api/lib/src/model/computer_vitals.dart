//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'computer_vitals.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ComputerVitals {
  /// Returns a new [ComputerVitals] instance.
  ComputerVitals({

    required  this.cpuPercent,

    required  this.memoryUsedBytes,

    required  this.memoryLimitBytes,

    required  this.diskUsedBytes,

    required  this.diskLimitBytes,

    required  this.at,
  });

      /// Of the CPUs it has, 0-100
  @JsonKey(
    
    name: r'cpu_percent',
    required: true,
    includeIfNull: false,
  )


  final num cpuPercent;



  @JsonKey(
    
    name: r'memory_used_bytes',
    required: true,
    includeIfNull: false,
  )


  final int memoryUsedBytes;



  @JsonKey(
    
    name: r'memory_limit_bytes',
    required: true,
    includeIfNull: false,
  )


  final int memoryLimitBytes;



  @JsonKey(
    
    name: r'disk_used_bytes',
    required: true,
    includeIfNull: false,
  )


  final int diskUsedBytes;



  @JsonKey(
    
    name: r'disk_limit_bytes',
    required: true,
    includeIfNull: false,
  )


  final int diskLimitBytes;



  @JsonKey(
    
    name: r'at',
    required: true,
    includeIfNull: false,
  )


  final DateTime at;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ComputerVitals &&
      other.cpuPercent == cpuPercent &&
      other.memoryUsedBytes == memoryUsedBytes &&
      other.memoryLimitBytes == memoryLimitBytes &&
      other.diskUsedBytes == diskUsedBytes &&
      other.diskLimitBytes == diskLimitBytes &&
      other.at == at;

    @override
    int get hashCode =>
        cpuPercent.hashCode +
        memoryUsedBytes.hashCode +
        memoryLimitBytes.hashCode +
        diskUsedBytes.hashCode +
        diskLimitBytes.hashCode +
        at.hashCode;

  factory ComputerVitals.fromJson(Map<String, dynamic> json) => _$ComputerVitalsFromJson(json);

  Map<String, dynamic> toJson() => _$ComputerVitalsToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

