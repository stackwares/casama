//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'canvas_background.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CanvasBackground {
  /// Returns a new [CanvasBackground] instance.
  CanvasBackground({

    required  this.kind,

    required  this.color,

    required  this.from,

    required  this.to,

    required  this.picture,
  });

  @JsonKey(
    
    name: r'kind',
    required: true,
    includeIfNull: false,
  )


  final CanvasBackgroundKindEnum kind;



  @JsonKey(
    
    name: r'color',
    required: true,
    includeIfNull: true,
  )


  final String? color;



  @JsonKey(
    
    name: r'from',
    required: true,
    includeIfNull: true,
  )


  final String? from;



  @JsonKey(
    
    name: r'to',
    required: true,
    includeIfNull: true,
  )


  final String? to;



  @JsonKey(
    
    name: r'picture',
    required: true,
    includeIfNull: true,
  )


  final String? picture;





    @override
    bool operator ==(Object other) => identical(this, other) || other is CanvasBackground &&
      other.kind == kind &&
      other.color == color &&
      other.from == from &&
      other.to == to &&
      other.picture == picture;

    @override
    int get hashCode =>
        kind.hashCode +
        (color == null ? 0 : color.hashCode) +
        (from == null ? 0 : from.hashCode) +
        (to == null ? 0 : to.hashCode) +
        (picture == null ? 0 : picture.hashCode);

  factory CanvasBackground.fromJson(Map<String, dynamic> json) => _$CanvasBackgroundFromJson(json);

  Map<String, dynamic> toJson() => _$CanvasBackgroundToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum CanvasBackgroundKindEnum {
@JsonValue(r'auto')
auto(r'auto'),
@JsonValue(r'color')
color(r'color'),
@JsonValue(r'gradient')
gradient(r'gradient'),
@JsonValue(r'picture')
picture(r'picture');

const CanvasBackgroundKindEnum(this.value);

final String value;

@override
String toString() => value;
}


