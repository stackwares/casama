//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'card_units.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CardUnits {
  /// Returns a new [CardUnits] instance.
  CardUnits({

     this.temp,

     this.wind,

     this.precip,

     this.distance,
  });

  @JsonKey(
    
    name: r'temp',
    required: false,
    includeIfNull: false,
  )


  final CardUnitsTempEnum? temp;



  @JsonKey(
    
    name: r'wind',
    required: false,
    includeIfNull: false,
  )


  final CardUnitsWindEnum? wind;



  @JsonKey(
    
    name: r'precip',
    required: false,
    includeIfNull: false,
  )


  final CardUnitsPrecipEnum? precip;



  @JsonKey(
    
    name: r'distance',
    required: false,
    includeIfNull: false,
  )


  final CardUnitsDistanceEnum? distance;





    @override
    bool operator ==(Object other) => identical(this, other) || other is CardUnits &&
      other.temp == temp &&
      other.wind == wind &&
      other.precip == precip &&
      other.distance == distance;

    @override
    int get hashCode =>
        temp.hashCode +
        wind.hashCode +
        precip.hashCode +
        distance.hashCode;

  factory CardUnits.fromJson(Map<String, dynamic> json) => _$CardUnitsFromJson(json);

  Map<String, dynamic> toJson() => _$CardUnitsToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum CardUnitsTempEnum {
@JsonValue(r'C')
C(r'C'),
@JsonValue(r'F')
F(r'F');

const CardUnitsTempEnum(this.value);

final String value;

@override
String toString() => value;
}



enum CardUnitsWindEnum {
@JsonValue(r'kph')
kph(r'kph'),
@JsonValue(r'mph')
mph(r'mph'),
@JsonValue(r'ms')
ms(r'ms'),
@JsonValue(r'kn')
kn(r'kn');

const CardUnitsWindEnum(this.value);

final String value;

@override
String toString() => value;
}



enum CardUnitsPrecipEnum {
@JsonValue(r'mm')
mm(r'mm'),
@JsonValue(r'in')
in_(r'in');

const CardUnitsPrecipEnum(this.value);

final String value;

@override
String toString() => value;
}



enum CardUnitsDistanceEnum {
@JsonValue(r'km')
km(r'km'),
@JsonValue(r'mi')
mi(r'mi');

const CardUnitsDistanceEnum(this.value);

final String value;

@override
String toString() => value;
}


