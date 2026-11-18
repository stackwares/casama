//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/browser_trigger_list_items_inner.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'browser_trigger_list.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class BrowserTriggerList {
  /// Returns a new [BrowserTriggerList] instance.
  BrowserTriggerList({

    required  this.items,
  });

  @JsonKey(
    
    name: r'items',
    required: true,
    includeIfNull: false,
  )


  final List<BrowserTriggerListItemsInner> items;





    @override
    bool operator ==(Object other) => identical(this, other) || other is BrowserTriggerList &&
      other.items == items;

    @override
    int get hashCode =>
        items.hashCode;

  factory BrowserTriggerList.fromJson(Map<String, dynamic> json) => _$BrowserTriggerListFromJson(json);

  Map<String, dynamic> toJson() => _$BrowserTriggerListToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

