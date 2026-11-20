//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'bot_picture_crop.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class BotPictureCrop {
  /// Returns a new [BotPictureCrop] instance.
  BotPictureCrop({

    required  this.x,

    required  this.y,

    required  this.scale,

    required  this.rotation,

    required  this.mirror,

    required  this.background,
  });

      /// Centre of the frame on the original, 0–1 across
          // minimum: -10
          // maximum: 10
  @JsonKey(
    
    name: r'x',
    required: true,
    includeIfNull: false,
  )


  final num x;



      /// Centre of the frame on the original, 0–1 down
          // minimum: -10
          // maximum: 10
  @JsonKey(
    
    name: r'y',
    required: true,
    includeIfNull: false,
  )


  final num y;



      /// Frame side as a share of the original's shorter side
          // minimum: 0.01
          // maximum: 100
  @JsonKey(
    
    name: r'scale',
    required: true,
    includeIfNull: false,
  )


  final num scale;



      /// Quarter turns clockwise
          // minimum: 0
          // maximum: 3
  @JsonKey(
    
    name: r'rotation',
    required: true,
    includeIfNull: false,
  )


  final int rotation;



  @JsonKey(
    
    name: r'mirror',
    required: true,
    includeIfNull: false,
  )


  final bool mirror;



      /// What fills see-through parts
  @JsonKey(
    
    name: r'background',
    required: true,
    includeIfNull: false,
  )


  final BotPictureCropBackgroundEnum background;





    @override
    bool operator ==(Object other) => identical(this, other) || other is BotPictureCrop &&
      other.x == x &&
      other.y == y &&
      other.scale == scale &&
      other.rotation == rotation &&
      other.mirror == mirror &&
      other.background == background;

    @override
    int get hashCode =>
        x.hashCode +
        y.hashCode +
        scale.hashCode +
        rotation.hashCode +
        mirror.hashCode +
        background.hashCode;

  factory BotPictureCrop.fromJson(Map<String, dynamic> json) => _$BotPictureCropFromJson(json);

  Map<String, dynamic> toJson() => _$BotPictureCropToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

/// What fills see-through parts
enum BotPictureCropBackgroundEnum {
    /// What fills see-through parts
@JsonValue(r'none')
none(r'none'),
    /// What fills see-through parts
@JsonValue(r'bot')
bot(r'bot'),
    /// What fills see-through parts
@JsonValue(r'white')
white(r'white'),
    /// What fills see-through parts
@JsonValue(r'black')
black(r'black');

const BotPictureCropBackgroundEnum(this.value);

final String value;

@override
String toString() => value;
}


