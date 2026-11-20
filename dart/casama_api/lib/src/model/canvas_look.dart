//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/canvas_background.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'canvas_look.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CanvasLook {
  /// Returns a new [CanvasLook] instance.
  CanvasLook({

    required  this.background,

    required  this.font,

    required  this.align,

    required  this.icon,

    required  this.accent,

    required  this.ink,
  });

  @JsonKey(
    
    name: r'background',
    required: true,
    includeIfNull: false,
  )


  final CanvasBackground background;



  @JsonKey(
    
    name: r'font',
    required: true,
    includeIfNull: false,
  )


  final CanvasLookFontEnum font;



  @JsonKey(
    
    name: r'align',
    required: true,
    includeIfNull: false,
  )


  final CanvasLookAlignEnum align;



  @JsonKey(
    
    name: r'icon',
    required: true,
    includeIfNull: true,
  )


  final String? icon;



  @JsonKey(
    
    name: r'accent',
    required: true,
    includeIfNull: true,
  )


  final String? accent;



  @JsonKey(
    
    name: r'ink',
    required: true,
    includeIfNull: false,
  )


  final CanvasLookInkEnum ink;





    @override
    bool operator ==(Object other) => identical(this, other) || other is CanvasLook &&
      other.background == background &&
      other.font == font &&
      other.align == align &&
      other.icon == icon &&
      other.accent == accent &&
      other.ink == ink;

    @override
    int get hashCode =>
        background.hashCode +
        font.hashCode +
        align.hashCode +
        (icon == null ? 0 : icon.hashCode) +
        (accent == null ? 0 : accent.hashCode) +
        ink.hashCode;

  factory CanvasLook.fromJson(Map<String, dynamic> json) => _$CanvasLookFromJson(json);

  Map<String, dynamic> toJson() => _$CanvasLookToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum CanvasLookFontEnum {
@JsonValue(r'plain')
plain(r'plain'),
@JsonValue(r'serif')
serif(r'serif'),
@JsonValue(r'rounded')
rounded(r'rounded'),
@JsonValue(r'mono')
mono(r'mono');

const CanvasLookFontEnum(this.value);

final String value;

@override
String toString() => value;
}



enum CanvasLookAlignEnum {
@JsonValue(r'start')
start(r'start'),
@JsonValue(r'center')
center(r'center');

const CanvasLookAlignEnum(this.value);

final String value;

@override
String toString() => value;
}



enum CanvasLookInkEnum {
@JsonValue(r'light')
light(r'light'),
@JsonValue(r'dark')
dark(r'dark'),
@JsonValue(r'auto')
auto(r'auto');

const CanvasLookInkEnum(this.value);

final String value;

@override
String toString() => value;
}


