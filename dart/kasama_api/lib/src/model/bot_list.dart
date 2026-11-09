//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:kasama_api/src/model/bot.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'bot_list.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class BotList {
  /// Returns a new [BotList] instance.
  BotList({

    required  this.items,
  });

  @JsonKey(
    
    name: r'items',
    required: true,
    includeIfNull: false,
  )


  final List<Bot> items;





    @override
    bool operator ==(Object other) => identical(this, other) || other is BotList &&
      other.items == items;

    @override
    int get hashCode =>
        items.hashCode;

  factory BotList.fromJson(Map<String, dynamic> json) => _$BotListFromJson(json);

  Map<String, dynamic> toJson() => _$BotListToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

