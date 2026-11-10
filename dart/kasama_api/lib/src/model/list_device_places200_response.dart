//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:kasama_api/src/model/device_place.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'list_device_places200_response.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ListDevicePlaces200Response {
  /// Returns a new [ListDevicePlaces200Response] instance.
  ListDevicePlaces200Response({

    required  this.items,
  });

  @JsonKey(
    
    name: r'items',
    required: true,
    includeIfNull: false,
  )


  final List<DevicePlace> items;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ListDevicePlaces200Response &&
      other.items == items;

    @override
    int get hashCode =>
        items.hashCode;

  factory ListDevicePlaces200Response.fromJson(Map<String, dynamic> json) => _$ListDevicePlaces200ResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ListDevicePlaces200ResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

