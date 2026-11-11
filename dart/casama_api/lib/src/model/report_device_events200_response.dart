//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'report_device_events200_response.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ReportDeviceEvents200Response {
  /// Returns a new [ReportDeviceEvents200Response] instance.
  ReportDeviceEvents200Response({

    required  this.accepted,

    required  this.runs,
  });

  @JsonKey(
    
    name: r'accepted',
    required: true,
    includeIfNull: false,
  )


  final int accepted;



  @JsonKey(
    
    name: r'runs',
    required: true,
    includeIfNull: false,
  )


  final int runs;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ReportDeviceEvents200Response &&
      other.accepted == accepted &&
      other.runs == runs;

    @override
    int get hashCode =>
        accepted.hashCode +
        runs.hashCode;

  factory ReportDeviceEvents200Response.fromJson(Map<String, dynamic> json) => _$ReportDeviceEvents200ResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ReportDeviceEvents200ResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

