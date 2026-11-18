//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'server_capacity_days_inner.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ServerCapacityDaysInner {
  /// Returns a new [ServerCapacityDaysInner] instance.
  ServerCapacityDaysInner({

    required  this.day,

    required  this.peakComputersMemMb,

    required  this.peakComputers,

    required  this.minAvailableMb,

    required  this.peakLoad1,
  });

  @JsonKey(
    
    name: r'day',
    required: true,
    includeIfNull: false,
  )


  final String day;



  @JsonKey(
    
    name: r'peak_computers_mem_mb',
    required: true,
    includeIfNull: false,
  )


  final int peakComputersMemMb;



  @JsonKey(
    
    name: r'peak_computers',
    required: true,
    includeIfNull: false,
  )


  final int peakComputers;



  @JsonKey(
    
    name: r'min_available_mb',
    required: true,
    includeIfNull: false,
  )


  final int minAvailableMb;



  @JsonKey(
    
    name: r'peak_load1',
    required: true,
    includeIfNull: false,
  )


  final num peakLoad1;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ServerCapacityDaysInner &&
      other.day == day &&
      other.peakComputersMemMb == peakComputersMemMb &&
      other.peakComputers == peakComputers &&
      other.minAvailableMb == minAvailableMb &&
      other.peakLoad1 == peakLoad1;

    @override
    int get hashCode =>
        day.hashCode +
        peakComputersMemMb.hashCode +
        peakComputers.hashCode +
        minAvailableMb.hashCode +
        peakLoad1.hashCode;

  factory ServerCapacityDaysInner.fromJson(Map<String, dynamic> json) => _$ServerCapacityDaysInnerFromJson(json);

  Map<String, dynamic> toJson() => _$ServerCapacityDaysInnerToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

