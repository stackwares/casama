//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/installed_plugin_server_all_of_tools.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'installed_plugin_server.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class InstalledPluginServer {
  /// Returns a new [InstalledPluginServer] instance.
  InstalledPluginServer({

    required  this.key,

    required  this.type,

    required  this.command,

    required  this.args,

    required  this.url,

    required  this.integrationId,

    required  this.status,

    required  this.error,

    required  this.tools,
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


  final InstalledPluginServerTypeEnum type;



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



  @JsonKey(
    
    name: r'integration_id',
    required: true,
    includeIfNull: false,
  )


  final String integrationId;



  @JsonKey(
    
    name: r'status',
    required: true,
    includeIfNull: false,
  )


  final InstalledPluginServerStatusEnum status;



  @JsonKey(
    
    name: r'error',
    required: true,
    includeIfNull: true,
  )


  final String? error;



  @JsonKey(
    
    name: r'tools',
    required: true,
    includeIfNull: false,
  )


  final List<InstalledPluginServerAllOfTools> tools;





    @override
    bool operator ==(Object other) => identical(this, other) || other is InstalledPluginServer &&
      other.key == key &&
      other.type == type &&
      other.command == command &&
      other.args == args &&
      other.url == url &&
      other.integrationId == integrationId &&
      other.status == status &&
      other.error == error &&
      other.tools == tools;

    @override
    int get hashCode =>
        key.hashCode +
        type.hashCode +
        (command == null ? 0 : command.hashCode) +
        args.hashCode +
        (url == null ? 0 : url.hashCode) +
        integrationId.hashCode +
        status.hashCode +
        (error == null ? 0 : error.hashCode) +
        tools.hashCode;

  factory InstalledPluginServer.fromJson(Map<String, dynamic> json) => _$InstalledPluginServerFromJson(json);

  Map<String, dynamic> toJson() => _$InstalledPluginServerToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum InstalledPluginServerTypeEnum {
@JsonValue(r'stdio')
stdio(r'stdio'),
@JsonValue(r'streamable-http')
streamableHttp(r'streamable-http'),
@JsonValue(r'sse')
sse(r'sse');

const InstalledPluginServerTypeEnum(this.value);

final String value;

@override
String toString() => value;
}



enum InstalledPluginServerStatusEnum {
@JsonValue(r'pending')
pending(r'pending'),
@JsonValue(r'ok')
ok(r'ok'),
@JsonValue(r'error')
error(r'error');

const InstalledPluginServerStatusEnum(this.value);

final String value;

@override
String toString() => value;
}


