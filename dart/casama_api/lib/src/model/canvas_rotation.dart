//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'canvas_rotation.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CanvasRotation {
  /// Returns a new [CanvasRotation] instance.
  CanvasRotation({

    required  this.count,

    required  this.showing,

    required  this.left,

    required  this.every,
  });

  @JsonKey(
    
    name: r'count',
    required: true,
    includeIfNull: false,
  )


  final int count;



  @JsonKey(
    
    name: r'showing',
    required: true,
    includeIfNull: false,
  )


  final int showing;



  @JsonKey(
    
    name: r'left',
    required: true,
    includeIfNull: false,
  )


  final int left;



  @JsonKey(
    
    name: r'every',
    required: true,
    includeIfNull: false,
  )


  final String every;





    @override
    bool operator ==(Object other) => identical(this, other) || other is CanvasRotation &&
      other.count == count &&
      other.showing == showing &&
      other.left == left &&
      other.every == every;

    @override
    int get hashCode =>
        count.hashCode +
        showing.hashCode +
        left.hashCode +
        every.hashCode;

  factory CanvasRotation.fromJson(Map<String, dynamic> json) => _$CanvasRotationFromJson(json);

  Map<String, dynamic> toJson() => _$CanvasRotationToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

