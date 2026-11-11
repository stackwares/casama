//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/plugin.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'plugin_list.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PluginList {
  /// Returns a new [PluginList] instance.
  PluginList({

    required  this.items,
  });

  @JsonKey(
    
    name: r'items',
    required: true,
    includeIfNull: false,
  )


  final List<Plugin> items;





    @override
    bool operator ==(Object other) => identical(this, other) || other is PluginList &&
      other.items == items;

    @override
    int get hashCode =>
        items.hashCode;

  factory PluginList.fromJson(Map<String, dynamic> json) => _$PluginListFromJson(json);

  Map<String, dynamic> toJson() => _$PluginListToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

