//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/link_server.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'link_server_list.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class LinkServerList {
  /// Returns a new [LinkServerList] instance.
  LinkServerList({

    required  this.items,

    required  this.limit,
  });

  @JsonKey(
    
    name: r'items',
    required: true,
    includeIfNull: false,
  )


  final List<LinkServer> items;



      /// Servers this workspace's plan connects
  @JsonKey(
    
    name: r'limit',
    required: true,
    includeIfNull: false,
  )


  final int limit;





    @override
    bool operator ==(Object other) => identical(this, other) || other is LinkServerList &&
      other.items == items &&
      other.limit == limit;

    @override
    int get hashCode =>
        items.hashCode +
        limit.hashCode;

  factory LinkServerList.fromJson(Map<String, dynamic> json) => _$LinkServerListFromJson(json);

  Map<String, dynamic> toJson() => _$LinkServerListToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

