//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'save_device_place_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SaveDevicePlaceRequest {
  /// Returns a new [SaveDevicePlaceRequest] instance.
  SaveDevicePlaceRequest({

    required  this.name,

    required  this.latitude,

    required  this.longitude,

     this.radiusM,
  });

  @JsonKey(
    
    name: r'name',
    required: true,
    includeIfNull: false,
  )


  final String name;



          // minimum: -90
          // maximum: 90
  @JsonKey(
    
    name: r'latitude',
    required: true,
    includeIfNull: false,
  )


  final num latitude;



          // minimum: -180
          // maximum: 180
  @JsonKey(
    
    name: r'longitude',
    required: true,
    includeIfNull: false,
  )


  final num longitude;



          // minimum: 50
          // maximum: 2000
  @JsonKey(
    
    name: r'radius_m',
    required: false,
    includeIfNull: false,
  )


  final int? radiusM;





    @override
    bool operator ==(Object other) => identical(this, other) || other is SaveDevicePlaceRequest &&
      other.name == name &&
      other.latitude == latitude &&
      other.longitude == longitude &&
      other.radiusM == radiusM;

    @override
    int get hashCode =>
        name.hashCode +
        latitude.hashCode +
        longitude.hashCode +
        radiusM.hashCode;

  factory SaveDevicePlaceRequest.fromJson(Map<String, dynamic> json) => _$SaveDevicePlaceRequestFromJson(json);

  Map<String, dynamic> toJson() => _$SaveDevicePlaceRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

