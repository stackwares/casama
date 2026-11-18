//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/secret_kind.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'secret.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Secret {
  /// Returns a new [Secret] instance.
  Secret({

    required  this.id,

    required  this.orgId,

    required  this.name,

    required  this.allowedHosts,

    required  this.allowedBotIds,

    required  this.kind,

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
    
    name: r'name',
    required: true,
    includeIfNull: false,
  )


  final String name;



  @JsonKey(
    
    name: r'allowed_hosts',
    required: true,
    includeIfNull: false,
  )


  final List<String> allowedHosts;



  @JsonKey(
    
    name: r'allowed_bot_ids',
    required: true,
    includeIfNull: true,
  )


  final List<String>? allowedBotIds;



  @JsonKey(
    
    name: r'kind',
    required: true,
    includeIfNull: false,
  )


  final SecretKind kind;



  @JsonKey(
    
    name: r'created_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime createdAt;





    @override
    bool operator ==(Object other) => identical(this, other) || other is Secret &&
      other.id == id &&
      other.orgId == orgId &&
      other.name == name &&
      other.allowedHosts == allowedHosts &&
      other.allowedBotIds == allowedBotIds &&
      other.kind == kind &&
      other.createdAt == createdAt;

    @override
    int get hashCode =>
        id.hashCode +
        orgId.hashCode +
        name.hashCode +
        allowedHosts.hashCode +
        (allowedBotIds == null ? 0 : allowedBotIds.hashCode) +
        kind.hashCode +
        createdAt.hashCode;

  factory Secret.fromJson(Map<String, dynamic> json) => _$SecretFromJson(json);

  Map<String, dynamic> toJson() => _$SecretToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

