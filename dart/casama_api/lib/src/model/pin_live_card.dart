//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/card_units.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'pin_live_card.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PinLiveCard {
  /// Returns a new [PinLiveCard] instance.
  PinLiveCard({

     this.units,
  });

  @JsonKey(
    
    name: r'units',
    required: false,
    includeIfNull: false,
  )


  final CardUnits? units;





    @override
    bool operator ==(Object other) => identical(this, other) || other is PinLiveCard &&
      other.units == units;

    @override
    int get hashCode =>
        (units == null ? 0 : units.hashCode);

  factory PinLiveCard.fromJson(Map<String, dynamic> json) => _$PinLiveCardFromJson(json);

  Map<String, dynamic> toJson() => _$PinLiveCardToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

