//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:kasama_api/src/model/integration_kind.dart';
import 'package:kasama_api/src/model/integration_tools_inner.dart';
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
      other.createdAt == createdAt;

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
        createdAt.hashCode;

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


