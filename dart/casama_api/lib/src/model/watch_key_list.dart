//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/watch_key.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'watch_key_list.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class WatchKeyList {
  /// Returns a new [WatchKeyList] instance.
  WatchKeyList({

    required  this.items,
  });

  @JsonKey(
    
    name: r'items',
    required: true,
    includeIfNull: false,
  )


  final List<WatchKey> items;





    @override
    bool operator ==(Object other) => identical(this, other) || other is WatchKeyList &&
      other.items == items;

    @override
    int get hashCode =>
        items.hashCode;

  factory WatchKeyList.fromJson(Map<String, dynamic> json) => _$WatchKeyListFromJson(json);

  Map<String, dynamic> toJson() => _$WatchKeyListToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

