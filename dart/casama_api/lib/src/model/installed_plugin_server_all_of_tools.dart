//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'installed_plugin_server_all_of_tools.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class InstalledPluginServerAllOfTools {
  /// Returns a new [InstalledPluginServerAllOfTools] instance.
  InstalledPluginServerAllOfTools({

    required  this.name,

    required  this.risk,
  });

  @JsonKey(
    
    name: r'name',
    required: true,
    includeIfNull: false,
  )


  final String name;



  @JsonKey(
    
    name: r'risk',
    required: true,
    includeIfNull: false,
  )


  final InstalledPluginServerAllOfToolsRiskEnum risk;





    @override
    bool operator ==(Object other) => identical(this, other) || other is InstalledPluginServerAllOfTools &&
      other.name == name &&
      other.risk == risk;

    @override
    int get hashCode =>
        name.hashCode +
        risk.hashCode;

  factory InstalledPluginServerAllOfTools.fromJson(Map<String, dynamic> json) => _$InstalledPluginServerAllOfToolsFromJson(json);

  Map<String, dynamic> toJson() => _$InstalledPluginServerAllOfToolsToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum InstalledPluginServerAllOfToolsRiskEnum {
@JsonValue(r'low')
low(r'low'),
@JsonValue(r'medium')
medium(r'medium'),
@JsonValue(r'high')
high(r'high');

const InstalledPluginServerAllOfToolsRiskEnum(this.value);

final String value;

@override
String toString() => value;
}


