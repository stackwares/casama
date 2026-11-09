//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:kasama_api/src/model/memory.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'memory_list.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class MemoryList {
  /// Returns a new [MemoryList] instance.
  MemoryList({

    required  this.items,
  });

  @JsonKey(
    
    name: r'items',
    required: true,
    includeIfNull: false,
  )


  final List<Memory> items;





    @override
    bool operator ==(Object other) => identical(this, other) || other is MemoryList &&
      other.items == items;

    @override
    int get hashCode =>
        items.hashCode;

  factory MemoryList.fromJson(Map<String, dynamic> json) => _$MemoryListFromJson(json);

  Map<String, dynamic> toJson() => _$MemoryListToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

