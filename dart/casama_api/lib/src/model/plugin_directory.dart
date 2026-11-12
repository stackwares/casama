//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/directory_plugin.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'plugin_directory.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PluginDirectory {
  /// Returns a new [PluginDirectory] instance.
  PluginDirectory({

    required  this.items,
  });

  @JsonKey(
    
    name: r'items',
    required: true,
    includeIfNull: false,
  )


  final List<DirectoryPlugin> items;





    @override
    bool operator ==(Object other) => identical(this, other) || other is PluginDirectory &&
      other.items == items;

    @override
    int get hashCode =>
        items.hashCode;

  factory PluginDirectory.fromJson(Map<String, dynamic> json) => _$PluginDirectoryFromJson(json);

  Map<String, dynamic> toJson() => _$PluginDirectoryToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

