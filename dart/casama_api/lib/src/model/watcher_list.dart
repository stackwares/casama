//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/watcher.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'watcher_list.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class WatcherList {
  /// Returns a new [WatcherList] instance.
  WatcherList({

    required  this.items,
  });

  @JsonKey(
    
    name: r'items',
    required: true,
    includeIfNull: false,
  )


  final List<Watcher> items;





    @override
    bool operator ==(Object other) => identical(this, other) || other is WatcherList &&
      other.items == items;

    @override
    int get hashCode =>
        items.hashCode;

  factory WatcherList.fromJson(Map<String, dynamic> json) => _$WatcherListFromJson(json);

  Map<String, dynamic> toJson() => _$WatcherListToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

