//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/mcp_connection.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'mcp_connection_list.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class McpConnectionList {
  /// Returns a new [McpConnectionList] instance.
  McpConnectionList({

    required  this.items,
  });

  @JsonKey(
    
    name: r'items',
    required: true,
    includeIfNull: false,
  )


  final List<McpConnection> items;





    @override
    bool operator ==(Object other) => identical(this, other) || other is McpConnectionList &&
      other.items == items;

    @override
    int get hashCode =>
        items.hashCode;

  factory McpConnectionList.fromJson(Map<String, dynamic> json) => _$McpConnectionListFromJson(json);

  Map<String, dynamic> toJson() => _$McpConnectionListToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

