//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/mcp_key.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'mcp_key_list.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class McpKeyList {
  /// Returns a new [McpKeyList] instance.
  McpKeyList({

    required  this.items,
  });

  @JsonKey(
    
    name: r'items',
    required: true,
    includeIfNull: false,
  )


  final List<McpKey> items;





    @override
    bool operator ==(Object other) => identical(this, other) || other is McpKeyList &&
      other.items == items;

    @override
    int get hashCode =>
        items.hashCode;

  factory McpKeyList.fromJson(Map<String, dynamic> json) => _$McpKeyListFromJson(json);

  Map<String, dynamic> toJson() => _$McpKeyListToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

