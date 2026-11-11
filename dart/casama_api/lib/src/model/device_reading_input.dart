//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/device_kind.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'device_reading_input.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class DeviceReadingInput {
  /// Returns a new [DeviceReadingInput] instance.
  DeviceReadingInput({

    required  this.kind,

    required  this.periodStart,

    required  this.periodEnd,

    required  this.externalId,

    required  this.summary,
  });

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





    @override
    bool operator ==(Object other) => identical(this, other) || other is DeviceReadingInput &&
      other.kind == kind &&
      other.periodStart == periodStart &&
      other.periodEnd == periodEnd &&
      other.externalId == externalId &&
      other.summary == summary;

    @override
    int get hashCode =>
        kind.hashCode +
        periodStart.hashCode +
        periodEnd.hashCode +
        externalId.hashCode +
        summary.hashCode;

  factory DeviceReadingInput.fromJson(Map<String, dynamic> json) => _$DeviceReadingInputFromJson(json);

  Map<String, dynamic> toJson() => _$DeviceReadingInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

