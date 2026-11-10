//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:kasama_api/src/model/replay.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'replay_list.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ReplayList {
  /// Returns a new [ReplayList] instance.
  ReplayList({

    required  this.items,
  });

  @JsonKey(
    
    name: r'items',
    required: true,
    includeIfNull: false,
  )


  final List<Replay> items;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ReplayList &&
      other.items == items;

    @override
    int get hashCode =>
        items.hashCode;

  factory ReplayList.fromJson(Map<String, dynamic> json) => _$ReplayListFromJson(json);

  Map<String, dynamic> toJson() => _$ReplayListToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

