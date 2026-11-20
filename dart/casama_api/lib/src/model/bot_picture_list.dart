//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/bot_picture.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'bot_picture_list.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class BotPictureList {
  /// Returns a new [BotPictureList] instance.
  BotPictureList({

    required  this.items,
  });

  @JsonKey(
    
    name: r'items',
    required: true,
    includeIfNull: false,
  )


  final List<BotPicture> items;





    @override
    bool operator ==(Object other) => identical(this, other) || other is BotPictureList &&
      other.items == items;

    @override
    int get hashCode =>
        items.hashCode;

  factory BotPictureList.fromJson(Map<String, dynamic> json) => _$BotPictureListFromJson(json);

  Map<String, dynamic> toJson() => _$BotPictureListToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

