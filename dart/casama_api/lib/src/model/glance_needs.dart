//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/glance_need.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'glance_needs.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class GlanceNeeds {
  /// Returns a new [GlanceNeeds] instance.
  GlanceNeeds({

    required  this.count,

    required  this.items,
  });

          // minimum: 0
  @JsonKey(
    
    name: r'count',
    required: true,
    includeIfNull: false,
  )


  final int count;



  @JsonKey(
    
    name: r'items',
    required: true,
    includeIfNull: false,
  )


  final List<GlanceNeed> items;





    @override
    bool operator ==(Object other) => identical(this, other) || other is GlanceNeeds &&
      other.count == count &&
      other.items == items;

    @override
    int get hashCode =>
        count.hashCode +
        items.hashCode;

  factory GlanceNeeds.fromJson(Map<String, dynamic> json) => _$GlanceNeedsFromJson(json);

  Map<String, dynamic> toJson() => _$GlanceNeedsToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

