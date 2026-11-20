//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/canvas_look.dart';
import 'package:casama_api/src/model/canvas_entry_items_inner.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'canvas_entry.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CanvasEntry {
  /// Returns a new [CanvasEntry] instance.
  CanvasEntry({

    required  this.at,

    required  this.template,

    required  this.title,

    required  this.text,

    required  this.footer,

    required  this.target,

    required  this.count,

    required  this.value,

    required  this.of_,

    required  this.unit,

    required  this.items,

    required  this.picture,

    required  this.short,

    required  this.tiny,

    required  this.look,
  });

  @JsonKey(
    
    name: r'at',
    required: true,
    includeIfNull: true,
  )


  final DateTime? at;



  @JsonKey(
    
    name: r'template',
    required: true,
    includeIfNull: false,
  )


  final CanvasEntryTemplateEnum template;



  @JsonKey(
    
    name: r'title',
    required: true,
    includeIfNull: true,
  )


  final String? title;



  @JsonKey(
    
    name: r'text',
    required: true,
    includeIfNull: true,
  )


  final String? text;



  @JsonKey(
    
    name: r'footer',
    required: true,
    includeIfNull: true,
  )


  final String? footer;



  @JsonKey(
    
    name: r'target',
    required: true,
    includeIfNull: true,
  )


  final DateTime? target;



  @JsonKey(
    
    name: r'count',
    required: true,
    includeIfNull: true,
  )


  final CanvasEntryCountEnum? count;



  @JsonKey(
    
    name: r'value',
    required: true,
    includeIfNull: true,
  )


  final num? value;



  @JsonKey(
    
    name: r'of',
    required: true,
    includeIfNull: true,
  )


  final num? of_;



  @JsonKey(
    
    name: r'unit',
    required: true,
    includeIfNull: true,
  )


  final String? unit;



  @JsonKey(
    
    name: r'items',
    required: true,
    includeIfNull: false,
  )


  final List<CanvasEntryItemsInner> items;



  @JsonKey(
    
    name: r'picture',
    required: true,
    includeIfNull: true,
  )


  final String? picture;



  @JsonKey(
    
    name: r'short',
    required: true,
    includeIfNull: false,
  )


  final String short;



  @JsonKey(
    
    name: r'tiny',
    required: true,
    includeIfNull: false,
  )


  final String tiny;



  @JsonKey(
    
    name: r'look',
    required: true,
    includeIfNull: false,
  )


  final CanvasLook look;





    @override
    bool operator ==(Object other) => identical(this, other) || other is CanvasEntry &&
      other.at == at &&
      other.template == template &&
      other.title == title &&
      other.text == text &&
      other.footer == footer &&
      other.target == target &&
      other.count == count &&
      other.value == value &&
      other.of_ == of_ &&
      other.unit == unit &&
      other.items == items &&
      other.picture == picture &&
      other.short == short &&
      other.tiny == tiny &&
      other.look == look;

    @override
    int get hashCode =>
        (at == null ? 0 : at.hashCode) +
        template.hashCode +
        (title == null ? 0 : title.hashCode) +
        (text == null ? 0 : text.hashCode) +
        (footer == null ? 0 : footer.hashCode) +
        (target == null ? 0 : target.hashCode) +
        (count == null ? 0 : count.hashCode) +
        (value == null ? 0 : value.hashCode) +
        (of_ == null ? 0 : of_.hashCode) +
        (unit == null ? 0 : unit.hashCode) +
        items.hashCode +
        (picture == null ? 0 : picture.hashCode) +
        short.hashCode +
        tiny.hashCode +
        look.hashCode;

  factory CanvasEntry.fromJson(Map<String, dynamic> json) => _$CanvasEntryFromJson(json);

  Map<String, dynamic> toJson() => _$CanvasEntryToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum CanvasEntryTemplateEnum {
@JsonValue(r'text')
text(r'text'),
@JsonValue(r'countdown')
countdown(r'countdown'),
@JsonValue(r'number')
number(r'number'),
@JsonValue(r'list')
list(r'list'),
@JsonValue(r'picture')
picture(r'picture');

const CanvasEntryTemplateEnum(this.value);

final String value;

@override
String toString() => value;
}



enum CanvasEntryCountEnum {
@JsonValue(r'down')
down(r'down'),
@JsonValue(r'up')
up(r'up');

const CanvasEntryCountEnum(this.value);

final String value;

@override
String toString() => value;
}


