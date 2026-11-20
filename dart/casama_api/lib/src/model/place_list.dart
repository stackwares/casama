//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/place.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'place_list.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PlaceList {
  /// Returns a new [PlaceList] instance.
  PlaceList({

    required  this.items,
  });

  @JsonKey(
    
    name: r'items',
    required: true,
    includeIfNull: false,
  )


  final List<Place> items;





    @override
    bool operator ==(Object other) => identical(this, other) || other is PlaceList &&
      other.items == items;

    @override
    int get hashCode =>
        items.hashCode;

  factory PlaceList.fromJson(Map<String, dynamic> json) => _$PlaceListFromJson(json);

  Map<String, dynamic> toJson() => _$PlaceListToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

