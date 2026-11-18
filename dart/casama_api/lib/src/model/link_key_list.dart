//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/link_key.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'link_key_list.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class LinkKeyList {
  /// Returns a new [LinkKeyList] instance.
  LinkKeyList({

    required  this.items,
  });

  @JsonKey(
    
    name: r'items',
    required: true,
    includeIfNull: false,
  )


  final List<LinkKey> items;





    @override
    bool operator ==(Object other) => identical(this, other) || other is LinkKeyList &&
      other.items == items;

    @override
    int get hashCode =>
        items.hashCode;

  factory LinkKeyList.fromJson(Map<String, dynamic> json) => _$LinkKeyListFromJson(json);

  Map<String, dynamic> toJson() => _$LinkKeyListToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

