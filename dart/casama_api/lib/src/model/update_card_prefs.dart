//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/card_prefs_units.dart';
import 'package:casama_api/src/model/card_prefs_home_place.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'update_card_prefs.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class UpdateCardPrefs {
  /// Returns a new [UpdateCardPrefs] instance.
  UpdateCardPrefs({

     this.homePlace,

     this.units,
  });

  @JsonKey(
    
    name: r'home_place',
    required: false,
    includeIfNull: false,
  )


  final CardPrefsHomePlace? homePlace;



  @JsonKey(
    
    name: r'units',
    required: false,
    includeIfNull: false,
  )


  final CardPrefsUnits? units;





    @override
    bool operator ==(Object other) => identical(this, other) || other is UpdateCardPrefs &&
      other.homePlace == homePlace &&
      other.units == units;

    @override
    int get hashCode =>
        (homePlace == null ? 0 : homePlace.hashCode) +
        (units == null ? 0 : units.hashCode);

  factory UpdateCardPrefs.fromJson(Map<String, dynamic> json) => _$UpdateCardPrefsFromJson(json);

  Map<String, dynamic> toJson() => _$UpdateCardPrefsToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

