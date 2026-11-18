//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'plugin_server_info.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PluginServerInfo {
  /// Returns a new [PluginServerInfo] instance.
  PluginServerInfo({

    required  this.key,

    required  this.type,

    required  this.command,

    required  this.args,

    required  this.url,
  });

  @JsonKey(
    
    name: r'key',
    required: true,
    includeIfNull: false,
  )


  final String key;



  @JsonKey(
    
    name: r'type',
    required: true,
    includeIfNull: false,
  )


  final PluginServerInfoTypeEnum type;



  @JsonKey(
    
    name: r'command',
    required: true,
    includeIfNull: true,
  )


  final String? command;



  @JsonKey(
    
    name: r'args',
    required: true,
    includeIfNull: false,
  )


  final List<String> args;



  @JsonKey(
    
    name: r'url',
    required: true,
    includeIfNull: true,
  )


  final String? url;





    @override
    bool operator ==(Object other) => identical(this, other) || other is PluginServerInfo &&
      other.key == key &&
      other.type == type &&
      other.command == command &&
      other.args == args &&
      other.url == url;

    @override
    int get hashCode =>
        key.hashCode +
        type.hashCode +
        (command == null ? 0 : command.hashCode) +
        args.hashCode +
        (url == null ? 0 : url.hashCode);

  factory PluginServerInfo.fromJson(Map<String, dynamic> json) => _$PluginServerInfoFromJson(json);

  Map<String, dynamic> toJson() => _$PluginServerInfoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum PluginServerInfoTypeEnum {
@JsonValue(r'stdio')
stdio(r'stdio'),
@JsonValue(r'streamable-http')
streamableHttp(r'streamable-http'),
@JsonValue(r'sse')
sse(r'sse');

const PluginServerInfoTypeEnum(this.value);

final String value;

@override
String toString() => value;
}


