//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'card_prefs_units.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CardPrefsUnits {
  /// Returns a new [CardPrefsUnits] instance.
  CardPrefsUnits({

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


  final CardPrefsUnitsTempEnum? temp;



  @JsonKey(
    
    name: r'wind',
    required: false,
    includeIfNull: false,
  )


  final CardPrefsUnitsWindEnum? wind;



  @JsonKey(
    
    name: r'precip',
    required: false,
    includeIfNull: false,
  )


  final CardPrefsUnitsPrecipEnum? precip;



  @JsonKey(
    
    name: r'distance',
    required: false,
    includeIfNull: false,
  )


  final CardPrefsUnitsDistanceEnum? distance;





    @override
    bool operator ==(Object other) => identical(this, other) || other is CardPrefsUnits &&
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

  factory CardPrefsUnits.fromJson(Map<String, dynamic> json) => _$CardPrefsUnitsFromJson(json);

  Map<String, dynamic> toJson() => _$CardPrefsUnitsToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum CardPrefsUnitsTempEnum {
@JsonValue(r'C')
C(r'C'),
@JsonValue(r'F')
F(r'F');

const CardPrefsUnitsTempEnum(this.value);

final String value;

@override
String toString() => value;
}



enum CardPrefsUnitsWindEnum {
@JsonValue(r'kph')
kph(r'kph'),
@JsonValue(r'mph')
mph(r'mph'),
@JsonValue(r'ms')
ms(r'ms'),
@JsonValue(r'kn')
kn(r'kn');

const CardPrefsUnitsWindEnum(this.value);

final String value;

@override
String toString() => value;
}



enum CardPrefsUnitsPrecipEnum {
@JsonValue(r'mm')
mm(r'mm'),
@JsonValue(r'in')
in_(r'in');

const CardPrefsUnitsPrecipEnum(this.value);

final String value;

@override
String toString() => value;
}



enum CardPrefsUnitsDistanceEnum {
@JsonValue(r'km')
km(r'km'),
@JsonValue(r'mi')
mi(r'mi');

const CardPrefsUnitsDistanceEnum(this.value);

final String value;

@override
String toString() => value;
}


