//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'canvas_grant_saved.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CanvasGrantSaved {
  /// Returns a new [CanvasGrantSaved] instance.
  CanvasGrantSaved({

    required  this.allowed,

    required  this.shown,

    required  this.cleared,
  });

  @JsonKey(
    
    name: r'allowed',
    required: true,
    includeIfNull: false,
  )


  final bool allowed;



  @JsonKey(
    
    name: r'shown',
    required: true,
    includeIfNull: false,
  )


  final int shown;



  @JsonKey(
    
    name: r'cleared',
    required: true,
    includeIfNull: false,
  )


  final int cleared;





    @override
    bool operator ==(Object other) => identical(this, other) || other is CanvasGrantSaved &&
      other.allowed == allowed &&
      other.shown == shown &&
      other.cleared == cleared;

    @override
    int get hashCode =>
        allowed.hashCode +
        shown.hashCode +
        cleared.hashCode;

  factory CanvasGrantSaved.fromJson(Map<String, dynamic> json) => _$CanvasGrantSavedFromJson(json);

  Map<String, dynamic> toJson() => _$CanvasGrantSavedToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

