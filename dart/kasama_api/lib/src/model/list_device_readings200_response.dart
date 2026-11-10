//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:kasama_api/src/model/device_reading.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'list_device_readings200_response.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ListDeviceReadings200Response {
  /// Returns a new [ListDeviceReadings200Response] instance.
  ListDeviceReadings200Response({

    required  this.items,
  });

  @JsonKey(
    
    name: r'items',
    required: true,
    includeIfNull: false,
  )


  final List<DeviceReading> items;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ListDeviceReadings200Response &&
      other.items == items;

    @override
    int get hashCode =>
        items.hashCode;

  factory ListDeviceReadings200Response.fromJson(Map<String, dynamic> json) => _$ListDeviceReadings200ResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ListDeviceReadings200ResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

