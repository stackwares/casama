//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/channel_event.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'channel_event_list.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ChannelEventList {
  /// Returns a new [ChannelEventList] instance.
  ChannelEventList({

    required  this.items,
  });

  @JsonKey(
    
    name: r'items',
    required: true,
    includeIfNull: false,
  )


  final List<ChannelEvent> items;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ChannelEventList &&
      other.items == items;

    @override
    int get hashCode =>
        items.hashCode;

  factory ChannelEventList.fromJson(Map<String, dynamic> json) => _$ChannelEventListFromJson(json);

  Map<String, dynamic> toJson() => _$ChannelEventListToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

