//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'plugin_secret_info.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PluginSecretInfo {
  /// Returns a new [PluginSecretInfo] instance.
  PluginSecretInfo({

    required  this.name,

    required  this.description,

    required  this.server,
  });

  @JsonKey(
    
    name: r'name',
    required: true,
    includeIfNull: false,
  )


  final String name;



  @JsonKey(
    
    name: r'description',
    required: true,
    includeIfNull: false,
  )


  final String description;



  @JsonKey(
    
    name: r'server',
    required: true,
    includeIfNull: false,
  )


  final String server;





    @override
    bool operator ==(Object other) => identical(this, other) || other is PluginSecretInfo &&
      other.name == name &&
      other.description == description &&
      other.server == server;

    @override
    int get hashCode =>
        name.hashCode +
        description.hashCode +
        server.hashCode;

  factory PluginSecretInfo.fromJson(Map<String, dynamic> json) => _$PluginSecretInfoFromJson(json);

  Map<String, dynamic> toJson() => _$PluginSecretInfoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

