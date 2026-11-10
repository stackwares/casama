//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:kasama_api/src/model/device_reading_input.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'upload_device_readings_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class UploadDeviceReadingsRequest {
  /// Returns a new [UploadDeviceReadingsRequest] instance.
  UploadDeviceReadingsRequest({

    required  this.readings,

     this.requestId,
  });

  @JsonKey(
    
    name: r'readings',
    required: true,
    includeIfNull: false,
  )


  final List<DeviceReadingInput> readings;



      /// Answers this fresh-read request
  @JsonKey(
    
    name: r'request_id',
    required: false,
    includeIfNull: false,
  )


  final String? requestId;





    @override
    bool operator ==(Object other) => identical(this, other) || other is UploadDeviceReadingsRequest &&
      other.readings == readings &&
      other.requestId == requestId;

    @override
    int get hashCode =>
        readings.hashCode +
        requestId.hashCode;

  factory UploadDeviceReadingsRequest.fromJson(Map<String, dynamic> json) => _$UploadDeviceReadingsRequestFromJson(json);

  Map<String, dynamic> toJson() => _$UploadDeviceReadingsRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

