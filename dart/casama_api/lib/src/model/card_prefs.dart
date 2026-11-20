//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/place.dart';
import 'package:casama_api/src/model/card_units.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'card_prefs.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CardPrefs {
  /// Returns a new [CardPrefs] instance.
  CardPrefs({

    required  this.homePlace,

    required  this.units,
  });

  @JsonKey(
    
    name: r'home_place',
    required: true,
    includeIfNull: true,
  )


  final Place? homePlace;



  @JsonKey(
    
    name: r'units',
    required: true,
    includeIfNull: true,
  )


  final CardUnits? units;





    @override
    bool operator ==(Object other) => identical(this, other) || other is CardPrefs &&
      other.homePlace == homePlace &&
      other.units == units;

    @override
    int get hashCode =>
        (homePlace == null ? 0 : homePlace.hashCode) +
        (units == null ? 0 : units.hashCode);

  factory CardPrefs.fromJson(Map<String, dynamic> json) => _$CardPrefsFromJson(json);

  Map<String, dynamic> toJson() => _$CardPrefsToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

