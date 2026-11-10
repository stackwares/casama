//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:kasama_api/src/model/device_kind.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'device_reading.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class DeviceReading {
  /// Returns a new [DeviceReading] instance.
  DeviceReading({

    required  this.id,

    required  this.sourceId,

    required  this.kind,

    required  this.periodStart,

    required  this.periodEnd,

    required  this.externalId,

    required  this.summary,

    required  this.collectedAt,
  });

  @JsonKey(
    
    name: r'id',
    required: true,
    includeIfNull: false,
  )


  final String id;



  @JsonKey(
    
    name: r'source_id',
    required: true,
    includeIfNull: false,
  )


  final String sourceId;



  @JsonKey(
    
    name: r'kind',
    required: true,
    includeIfNull: false,
  )


  final DeviceKind kind;



  @JsonKey(
    
    name: r'period_start',
    required: true,
    includeIfNull: false,
  )


  final DateTime periodStart;



  @JsonKey(
    
    name: r'period_end',
    required: true,
    includeIfNull: false,
  )


  final DateTime periodEnd;



  @JsonKey(
    
    name: r'external_id',
    required: true,
    includeIfNull: false,
  )


  final String externalId;



  @JsonKey(
    
    name: r'summary',
    required: true,
    includeIfNull: false,
  )


  final Map<String, Object?> summary;



  @JsonKey(
    
    name: r'collected_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime collectedAt;





    @override
    bool operator ==(Object other) => identical(this, other) || other is DeviceReading &&
      other.id == id &&
      other.sourceId == sourceId &&
      other.kind == kind &&
      other.periodStart == periodStart &&
      other.periodEnd == periodEnd &&
      other.externalId == externalId &&
      other.summary == summary &&
      other.collectedAt == collectedAt;

    @override
    int get hashCode =>
        id.hashCode +
        sourceId.hashCode +
        kind.hashCode +
        periodStart.hashCode +
        periodEnd.hashCode +
        externalId.hashCode +
        summary.hashCode +
        collectedAt.hashCode;

  factory DeviceReading.fromJson(Map<String, dynamic> json) => _$DeviceReadingFromJson(json);

  Map<String, dynamic> toJson() => _$DeviceReadingToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

