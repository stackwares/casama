//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/device_permissions.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'list_device_permissions200_response.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ListDevicePermissions200Response {
  /// Returns a new [ListDevicePermissions200Response] instance.
  ListDevicePermissions200Response({

    required  this.items,
  });

  @JsonKey(
    
    name: r'items',
    required: true,
    includeIfNull: false,
  )


  final List<DevicePermissions> items;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ListDevicePermissions200Response &&
      other.items == items;

    @override
    int get hashCode =>
        items.hashCode;

  factory ListDevicePermissions200Response.fromJson(Map<String, dynamic> json) => _$ListDevicePermissions200ResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ListDevicePermissions200ResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

