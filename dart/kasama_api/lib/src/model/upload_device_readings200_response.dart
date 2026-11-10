//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'upload_device_readings200_response.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class UploadDeviceReadings200Response {
  /// Returns a new [UploadDeviceReadings200Response] instance.
  UploadDeviceReadings200Response({

    required  this.stored,
  });

  @JsonKey(
    
    name: r'stored',
    required: true,
    includeIfNull: false,
  )


  final int stored;





    @override
    bool operator ==(Object other) => identical(this, other) || other is UploadDeviceReadings200Response &&
      other.stored == stored;

    @override
    int get hashCode =>
        stored.hashCode;

  factory UploadDeviceReadings200Response.fromJson(Map<String, dynamic> json) => _$UploadDeviceReadings200ResponseFromJson(json);

  Map<String, dynamic> toJson() => _$UploadDeviceReadings200ResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

