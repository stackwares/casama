//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/pack.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'pack_list.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PackList {
  /// Returns a new [PackList] instance.
  PackList({

    required  this.items,
  });

  @JsonKey(
    
    name: r'items',
    required: true,
    includeIfNull: false,
  )


  final List<Pack> items;





    @override
    bool operator ==(Object other) => identical(this, other) || other is PackList &&
      other.items == items;

    @override
    int get hashCode =>
        items.hashCode;

  factory PackList.fromJson(Map<String, dynamic> json) => _$PackListFromJson(json);

  Map<String, dynamic> toJson() => _$PackListToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

