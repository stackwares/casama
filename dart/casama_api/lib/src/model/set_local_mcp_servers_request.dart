//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/local_mcp_server_info.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'set_local_mcp_servers_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SetLocalMcpServersRequest {
  /// Returns a new [SetLocalMcpServersRequest] instance.
  SetLocalMcpServersRequest({

    required  this.servers,
  });

  @JsonKey(
    
    name: r'servers',
    required: true,
    includeIfNull: false,
  )


  final List<LocalMcpServerInfo> servers;





    @override
    bool operator ==(Object other) => identical(this, other) || other is SetLocalMcpServersRequest &&
      other.servers == servers;

    @override
    int get hashCode =>
        servers.hashCode;

  factory SetLocalMcpServersRequest.fromJson(Map<String, dynamic> json) => _$SetLocalMcpServersRequestFromJson(json);

  Map<String, dynamic> toJson() => _$SetLocalMcpServersRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

