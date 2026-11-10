//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:kasama_api/src/model/bot_page.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'page_list.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PageList {
  /// Returns a new [PageList] instance.
  PageList({

    required  this.items,
  });

  @JsonKey(
    
    name: r'items',
    required: true,
    includeIfNull: false,
  )


  final List<BotPage> items;





    @override
    bool operator ==(Object other) => identical(this, other) || other is PageList &&
      other.items == items;

    @override
    int get hashCode =>
        items.hashCode;

  factory PageList.fromJson(Map<String, dynamic> json) => _$PageListFromJson(json);

  Map<String, dynamic> toJson() => _$PageListToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

