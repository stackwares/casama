//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'browser_tab_summary.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class BrowserTabSummary {
  /// Returns a new [BrowserTabSummary] instance.
  BrowserTabSummary({

    required  this.type,

    required  this.url,

    required  this.title,

     this.selection,

     this.text,
  });

  @JsonKey(
    
    name: r'type',
    required: true,
    includeIfNull: false,
  )


  final BrowserTabSummaryTypeEnum type;



  @JsonKey(
    
    name: r'url',
    required: true,
    includeIfNull: false,
  )


  final String url;



  @JsonKey(
    
    name: r'title',
    required: true,
    includeIfNull: false,
  )


  final String title;



  @JsonKey(
    
    name: r'selection',
    required: false,
    includeIfNull: false,
  )


  final String? selection;



  @JsonKey(
    
    name: r'text',
    required: false,
    includeIfNull: false,
  )


  final String? text;





    @override
    bool operator ==(Object other) => identical(this, other) || other is BrowserTabSummary &&
      other.type == type &&
      other.url == url &&
      other.title == title &&
      other.selection == selection &&
      other.text == text;

    @override
    int get hashCode =>
        type.hashCode +
        url.hashCode +
        title.hashCode +
        selection.hashCode +
        text.hashCode;

  factory BrowserTabSummary.fromJson(Map<String, dynamic> json) => _$BrowserTabSummaryFromJson(json);

  Map<String, dynamic> toJson() => _$BrowserTabSummaryToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum BrowserTabSummaryTypeEnum {
@JsonValue(r'tab')
tab(r'tab');

const BrowserTabSummaryTypeEnum(this.value);

final String value;

@override
String toString() => value;
}


