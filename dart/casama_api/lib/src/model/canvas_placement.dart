//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'canvas_placement.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CanvasPlacement {
  /// Returns a new [CanvasPlacement] instance.
  CanvasPlacement({

    required  this.platform,

    required  this.label,

    required  this.sizes,

    required  this.seenAt,
  });

  @JsonKey(
    
    name: r'platform',
    required: true,
    includeIfNull: false,
  )


  final CanvasPlacementPlatformEnum platform;



  @JsonKey(
    
    name: r'label',
    required: true,
    includeIfNull: true,
  )


  final String? label;



  @JsonKey(
    
    name: r'sizes',
    required: true,
    includeIfNull: false,
  )


  final List<String> sizes;



  @JsonKey(
    
    name: r'seen_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime seenAt;





    @override
    bool operator ==(Object other) => identical(this, other) || other is CanvasPlacement &&
      other.platform == platform &&
      other.label == label &&
      other.sizes == sizes &&
      other.seenAt == seenAt;

    @override
    int get hashCode =>
        platform.hashCode +
        (label == null ? 0 : label.hashCode) +
        sizes.hashCode +
        seenAt.hashCode;

  factory CanvasPlacement.fromJson(Map<String, dynamic> json) => _$CanvasPlacementFromJson(json);

  Map<String, dynamic> toJson() => _$CanvasPlacementToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum CanvasPlacementPlatformEnum {
@JsonValue(r'ios')
ios(r'ios'),
@JsonValue(r'android')
android(r'android'),
@JsonValue(r'macos')
macos(r'macos');

const CanvasPlacementPlatformEnum(this.value);

final String value;

@override
String toString() => value;
}


