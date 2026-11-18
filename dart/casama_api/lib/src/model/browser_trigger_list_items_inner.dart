//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'browser_trigger_list_items_inner.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class BrowserTriggerListItemsInner {
  /// Returns a new [BrowserTriggerListItemsInner] instance.
  BrowserTriggerListItemsInner({

    required  this.event,

     this.site,

     this.pattern,
  });

  @JsonKey(
    
    name: r'event',
    required: true,
    includeIfNull: false,
  )


  final BrowserTriggerListItemsInnerEventEnum event;



  @JsonKey(
    
    name: r'site',
    required: false,
    includeIfNull: false,
  )


  final String? site;



  @JsonKey(
    
    name: r'pattern',
    required: false,
    includeIfNull: false,
  )


  final String? pattern;





    @override
    bool operator ==(Object other) => identical(this, other) || other is BrowserTriggerListItemsInner &&
      other.event == event &&
      other.site == site &&
      other.pattern == pattern;

    @override
    int get hashCode =>
        event.hashCode +
        site.hashCode +
        pattern.hashCode;

  factory BrowserTriggerListItemsInner.fromJson(Map<String, dynamic> json) => _$BrowserTriggerListItemsInnerFromJson(json);

  Map<String, dynamic> toJson() => _$BrowserTriggerListItemsInnerToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum BrowserTriggerListItemsInnerEventEnum {
@JsonValue(r'site_opened')
siteOpened(r'site_opened'),
@JsonValue(r'download_done')
downloadDone(r'download_done'),
@JsonValue(r'bookmark_added')
bookmarkAdded(r'bookmark_added');

const BrowserTriggerListItemsInnerEventEnum(this.value);

final String value;

@override
String toString() => value;
}


