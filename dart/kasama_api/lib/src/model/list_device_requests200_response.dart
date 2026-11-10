//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:kasama_api/src/model/device_request.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'list_device_requests200_response.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ListDeviceRequests200Response {
  /// Returns a new [ListDeviceRequests200Response] instance.
  ListDeviceRequests200Response({

    required  this.items,
  });

  @JsonKey(
    
    name: r'items',
    required: true,
    includeIfNull: false,
  )


  final List<DeviceRequest> items;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ListDeviceRequests200Response &&
      other.items == items;

    @override
    int get hashCode =>
        items.hashCode;

  factory ListDeviceRequests200Response.fromJson(Map<String, dynamic> json) => _$ListDeviceRequests200ResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ListDeviceRequests200ResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

