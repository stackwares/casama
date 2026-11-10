//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:kasama_api/src/model/risk.dart';
import 'package:kasama_api/src/model/integration_kind.dart';
import 'package:kasama_api/src/model/integration_tools_inner.dart';
import 'package:kasama_api/src/model/integration_device.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'integration.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Integration {
  /// Returns a new [Integration] instance.
  Integration({

    required  this.id,

    required  this.orgId,

    required  this.kind,

    required  this.name,

    required  this.status,

    required  this.error,

    required  this.tools,

    required  this.toolsCachedAt,

    required  this.createdAt,

     this.appId,

     this.auth,

     this.botIds,

     this.riskOverrides,

     this.device,
  });

  @JsonKey(
    
    name: r'id',
    required: true,
    includeIfNull: false,
  )


  final String id;



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



  @JsonKey(
    
    name: r'status',
    required: true,
    includeIfNull: false,
  )


  final IntegrationStatusEnum status;



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


  final List<IntegrationToolsInner> tools;



  @JsonKey(
    
    name: r'tools_cached_at',
    required: true,
    includeIfNull: true,
  )


  final DateTime? toolsCachedAt;



  @JsonKey(
    
    name: r'created_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime createdAt;



  @JsonKey(
    
    name: r'app_id',
    required: false,
    includeIfNull: false,
  )


  final String? appId;



  @JsonKey(
    
    name: r'auth',
    required: false,
    includeIfNull: false,
  )


  final IntegrationAuthEnum? auth;



  @JsonKey(
    
    name: r'bot_ids',
    required: false,
    includeIfNull: false,
  )


  final List<String>? botIds;



  @JsonKey(
    
    name: r'risk_overrides',
    required: false,
    includeIfNull: false,
  )


  final Map<String, Risk>? riskOverrides;



  @JsonKey(
    
    name: r'device',
    required: false,
    includeIfNull: false,
  )


  final IntegrationDevice? device;





    @override
    bool operator ==(Object other) => identical(this, other) || other is Integration &&
      other.id == id &&
      other.orgId == orgId &&
      other.kind == kind &&
      other.name == name &&
      other.status == status &&
      other.error == error &&
      other.tools == tools &&
      other.toolsCachedAt == toolsCachedAt &&
      other.createdAt == createdAt &&
      other.appId == appId &&
      other.auth == auth &&
      other.botIds == botIds &&
      other.riskOverrides == riskOverrides &&
      other.device == device;

    @override
    int get hashCode =>
        id.hashCode +
        orgId.hashCode +
        kind.hashCode +
        name.hashCode +
        status.hashCode +
        (error == null ? 0 : error.hashCode) +
        tools.hashCode +
        (toolsCachedAt == null ? 0 : toolsCachedAt.hashCode) +
        createdAt.hashCode +
        (appId == null ? 0 : appId.hashCode) +
        (auth == null ? 0 : auth.hashCode) +
        botIds.hashCode +
        riskOverrides.hashCode +
        (device == null ? 0 : device.hashCode);

  factory Integration.fromJson(Map<String, dynamic> json) => _$IntegrationFromJson(json);

  Map<String, dynamic> toJson() => _$IntegrationToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum IntegrationStatusEnum {
@JsonValue(r'pending')
pending(r'pending'),
@JsonValue(r'ok')
ok(r'ok'),
@JsonValue(r'error')
error(r'error');

const IntegrationStatusEnum(this.value);

final String value;

@override
String toString() => value;
}



enum IntegrationAuthEnum {
@JsonValue(r'oauth')
oauth(r'oauth'),
@JsonValue(r'api_key')
apiKey(r'api_key'),
@JsonValue(r'none')
none(r'none');

const IntegrationAuthEnum(this.value);

final String value;

@override
String toString() => value;
}


