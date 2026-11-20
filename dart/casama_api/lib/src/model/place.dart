//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'place.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Place {
  /// Returns a new [Place] instance.
  Place({

    required  this.name,

     this.region,

     this.country,

     this.countryName,

    required  this.lat,

    required  this.lng,

     this.tz,
  });

  @JsonKey(
    
    name: r'name',
    required: true,
    includeIfNull: false,
  )


  final String name;



  @JsonKey(
    
    name: r'region',
    required: false,
    includeIfNull: false,
  )


  final String? region;



  @JsonKey(
    
    name: r'country',
    required: false,
    includeIfNull: false,
  )


  final String? country;



  @JsonKey(
    
    name: r'country_name',
    required: false,
    includeIfNull: false,
  )


  final String? countryName;



  @JsonKey(
    
    name: r'lat',
    required: true,
    includeIfNull: false,
  )


  final num lat;



  @JsonKey(
    
    name: r'lng',
    required: true,
    includeIfNull: false,
  )


  final num lng;



  @JsonKey(
    
    name: r'tz',
    required: false,
    includeIfNull: false,
  )


  final String? tz;





    @override
    bool operator ==(Object other) => identical(this, other) || other is Place &&
      other.name == name &&
      other.region == region &&
      other.country == country &&
      other.countryName == countryName &&
      other.lat == lat &&
      other.lng == lng &&
      other.tz == tz;

    @override
    int get hashCode =>
        name.hashCode +
        (region == null ? 0 : region.hashCode) +
        (country == null ? 0 : country.hashCode) +
        (countryName == null ? 0 : countryName.hashCode) +
        lat.hashCode +
        lng.hashCode +
        (tz == null ? 0 : tz.hashCode);

  factory Place.fromJson(Map<String, dynamic> json) => _$PlaceFromJson(json);

  Map<String, dynamic> toJson() => _$PlaceToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

