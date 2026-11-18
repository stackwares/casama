//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'mcp_auth_request_info.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class McpAuthRequestInfo {
  /// Returns a new [McpAuthRequestInfo] instance.
  McpAuthRequestInfo({

    required  this.id,

    required  this.clientName,

    required  this.redirectHost,

    required  this.expiresAt,
  });

  @JsonKey(
    
    name: r'id',
    required: true,
    includeIfNull: false,
  )


  final String id;



  @JsonKey(
    
    name: r'client_name',
    required: true,
    includeIfNull: false,
  )


  final String clientName;



  @JsonKey(
    
    name: r'redirect_host',
    required: true,
    includeIfNull: false,
  )


  final String redirectHost;



  @JsonKey(
    
    name: r'expires_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime expiresAt;





    @override
    bool operator ==(Object other) => identical(this, other) || other is McpAuthRequestInfo &&
      other.id == id &&
      other.clientName == clientName &&
      other.redirectHost == redirectHost &&
      other.expiresAt == expiresAt;

    @override
    int get hashCode =>
        id.hashCode +
        clientName.hashCode +
        redirectHost.hashCode +
        expiresAt.hashCode;

  factory McpAuthRequestInfo.fromJson(Map<String, dynamic> json) => _$McpAuthRequestInfoFromJson(json);

  Map<String, dynamic> toJson() => _$McpAuthRequestInfoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

