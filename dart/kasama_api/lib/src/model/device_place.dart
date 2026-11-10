//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'device_place.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class DevicePlace {
  /// Returns a new [DevicePlace] instance.
  DevicePlace({

    required  this.id,

    required  this.name,

    required  this.latitude,

    required  this.longitude,

    required  this.radiusM,

    required  this.createdAt,
  });

  @JsonKey(
    
    name: r'id',
    required: true,
    includeIfNull: false,
  )


  final String id;



  @JsonKey(
    
    name: r'name',
    required: true,
    includeIfNull: false,
  )


  final String name;



  @JsonKey(
    
    name: r'latitude',
    required: true,
    includeIfNull: false,
  )


  final num latitude;



  @JsonKey(
    
    name: r'longitude',
    required: true,
    includeIfNull: false,
  )


  final num longitude;



  @JsonKey(
    
    name: r'radius_m',
    required: true,
    includeIfNull: false,
  )


  final int radiusM;



  @JsonKey(
    
    name: r'created_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime createdAt;





    @override
    bool operator ==(Object other) => identical(this, other) || other is DevicePlace &&
      other.id == id &&
      other.name == name &&
      other.latitude == latitude &&
      other.longitude == longitude &&
      other.radiusM == radiusM &&
      other.createdAt == createdAt;

    @override
    int get hashCode =>
        id.hashCode +
        name.hashCode +
        latitude.hashCode +
        longitude.hashCode +
        radiusM.hashCode +
        createdAt.hashCode;

  factory DevicePlace.fromJson(Map<String, dynamic> json) => _$DevicePlaceFromJson(json);

  Map<String, dynamic> toJson() => _$DevicePlaceToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

