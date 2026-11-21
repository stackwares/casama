//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/fare_watch.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'fare_watch_list.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class FareWatchList {
  /// Returns a new [FareWatchList] instance.
  FareWatchList({

    required  this.items,
  });

  @JsonKey(
    
    name: r'items',
    required: true,
    includeIfNull: false,
  )


  final List<FareWatch> items;





    @override
    bool operator ==(Object other) => identical(this, other) || other is FareWatchList &&
      other.items == items;

    @override
    int get hashCode =>
        items.hashCode;

  factory FareWatchList.fromJson(Map<String, dynamic> json) => _$FareWatchListFromJson(json);

  Map<String, dynamic> toJson() => _$FareWatchListToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

