//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/canvas_placement.dart';
import 'package:casama_api/src/model/canvas.dart';
import 'package:casama_api/src/model/canvas_grant.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'canvas_list.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CanvasList {
  /// Returns a new [CanvasList] instance.
  CanvasList({

    required  this.version,

    required  this.madeAt,

    required  this.private,

    required  this.items,

    required  this.grants,

    required  this.placed,
  });

  @JsonKey(
    
    name: r'version',
    required: true,
    includeIfNull: false,
  )


  final String version;



  @JsonKey(
    
    name: r'made_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime madeAt;



  @JsonKey(
    
    name: r'private',
    required: true,
    includeIfNull: false,
  )


  final bool private;



  @JsonKey(
    
    name: r'items',
    required: true,
    includeIfNull: false,
  )


  final List<Canvas> items;



  @JsonKey(
    
    name: r'grants',
    required: true,
    includeIfNull: false,
  )


  final List<CanvasGrant> grants;



  @JsonKey(
    
    name: r'placed',
    required: true,
    includeIfNull: false,
  )


  final List<CanvasPlacement> placed;





    @override
    bool operator ==(Object other) => identical(this, other) || other is CanvasList &&
      other.version == version &&
      other.madeAt == madeAt &&
      other.private == private &&
      other.items == items &&
      other.grants == grants &&
      other.placed == placed;

    @override
    int get hashCode =>
        version.hashCode +
        madeAt.hashCode +
        private.hashCode +
        items.hashCode +
        grants.hashCode +
        placed.hashCode;

  factory CanvasList.fromJson(Map<String, dynamic> json) => _$CanvasListFromJson(json);

  Map<String, dynamic> toJson() => _$CanvasListToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

