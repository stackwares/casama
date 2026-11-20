//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/live_card.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'live_card_list.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class LiveCardList {
  /// Returns a new [LiveCardList] instance.
  LiveCardList({

    required  this.items,
  });

  @JsonKey(
    
    name: r'items',
    required: true,
    includeIfNull: false,
  )


  final List<LiveCard> items;





    @override
    bool operator ==(Object other) => identical(this, other) || other is LiveCardList &&
      other.items == items;

    @override
    int get hashCode =>
        items.hashCode;

  factory LiveCardList.fromJson(Map<String, dynamic> json) => _$LiveCardListFromJson(json);

  Map<String, dynamic> toJson() => _$LiveCardListToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

