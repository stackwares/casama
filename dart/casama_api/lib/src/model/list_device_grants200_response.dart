//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/device_grant.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'list_device_grants200_response.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ListDeviceGrants200Response {
  /// Returns a new [ListDeviceGrants200Response] instance.
  ListDeviceGrants200Response({

    required  this.items,
  });

  @JsonKey(
    
    name: r'items',
    required: true,
    includeIfNull: false,
  )


  final List<DeviceGrant> items;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ListDeviceGrants200Response &&
      other.items == items;

    @override
    int get hashCode =>
        items.hashCode;

  factory ListDeviceGrants200Response.fromJson(Map<String, dynamic> json) => _$ListDeviceGrants200ResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ListDeviceGrants200ResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

