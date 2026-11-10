//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:kasama_api/src/model/device_source.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'list_device_sources200_response.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ListDeviceSources200Response {
  /// Returns a new [ListDeviceSources200Response] instance.
  ListDeviceSources200Response({

    required  this.items,
  });

  @JsonKey(
    
    name: r'items',
    required: true,
    includeIfNull: false,
  )


  final List<DeviceSource> items;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ListDeviceSources200Response &&
      other.items == items;

    @override
    int get hashCode =>
        items.hashCode;

  factory ListDeviceSources200Response.fromJson(Map<String, dynamic> json) => _$ListDeviceSources200ResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ListDeviceSources200ResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

