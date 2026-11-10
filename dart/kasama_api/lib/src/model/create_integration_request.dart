//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:kasama_api/src/model/integration_kind.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'create_integration_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CreateIntegrationRequest {
  /// Returns a new [CreateIntegrationRequest] instance.
  CreateIntegrationRequest({

    required  this.orgId,

    required  this.kind,

    required  this.name,

    required  this.config,

     this.secret,
  });

  @JsonKey(
    
    name: r'org_id',
    required: true,
    includeIfNull: false,
  )


  final String orgId;



  @JsonKey(
    
    name: r'kind',
    required: true,
    includeIfNull: false,
  )


  final IntegrationKind kind;



  @JsonKey(
    
    name: r'name',
    required: true,
    includeIfNull: false,
  )


  final String name;



      /// mcp: {url, auth_header?}; a2a: {url} (the agent's address or agent card; secret: its bearer token); openapi: {spec, base_url?, auth?: {type, header?, secret}}; composio: {toolkits[], user_id?}; pipedream: {project_id, client_id, apps[], environment?}
  @JsonKey(
    
    name: r'config',
    required: true,
    includeIfNull: false,
  )


  final Map<String, Object?> config;



      /// API key or client secret; stored in Vault
  @JsonKey(
    
    name: r'secret',
    required: false,
    includeIfNull: false,
  )


  final String? secret;





    @override
    bool operator ==(Object other) => identical(this, other) || other is CreateIntegrationRequest &&
      other.orgId == orgId &&
      other.kind == kind &&
      other.name == name &&
      other.config == config &&
      other.secret == secret;

    @override
    int get hashCode =>
        orgId.hashCode +
        kind.hashCode +
        name.hashCode +
        config.hashCode +
        secret.hashCode;

  factory CreateIntegrationRequest.fromJson(Map<String, dynamic> json) => _$CreateIntegrationRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CreateIntegrationRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

