//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/secret_kind.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'bot_secret_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class BotSecretRequest {
  /// Returns a new [BotSecretRequest] instance.
  BotSecretRequest({

    required  this.id,

    required  this.orgId,

    required  this.botId,

    required  this.runId,

    required  this.conversationId,

    required  this.name,

    required  this.service,

    required  this.allowedHosts,

    required  this.reason,

    required  this.kind,

    required  this.status,

    required  this.expiresAt,

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
    
    name: r'bot_id',
    required: true,
    includeIfNull: false,
  )


  final String botId;



  @JsonKey(
    
    name: r'run_id',
    required: true,
    includeIfNull: false,
  )


  final String runId;



  @JsonKey(
    
    name: r'conversation_id',
    required: true,
    includeIfNull: true,
  )


  final String? conversationId;



  @JsonKey(
    
    name: r'name',
    required: true,
    includeIfNull: false,
  )


  final String name;



  @JsonKey(
    
    name: r'service',
    required: true,
    includeIfNull: false,
  )


  final String service;



  @JsonKey(
    
    name: r'allowed_hosts',
    required: true,
    includeIfNull: false,
  )


  final List<String> allowedHosts;



  @JsonKey(
    
    name: r'reason',
    required: true,
    includeIfNull: false,
  )


  final String reason;



  @JsonKey(
    
    name: r'kind',
    required: true,
    includeIfNull: false,
  )


  final SecretKind kind;



  @JsonKey(
    
    name: r'status',
    required: true,
    includeIfNull: false,
  )


  final BotSecretRequestStatusEnum status;



  @JsonKey(
    
    name: r'expires_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime expiresAt;



  @JsonKey(
    
    name: r'created_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime createdAt;





    @override
    bool operator ==(Object other) => identical(this, other) || other is BotSecretRequest &&
      other.id == id &&
      other.orgId == orgId &&
      other.botId == botId &&
      other.runId == runId &&
      other.conversationId == conversationId &&
      other.name == name &&
      other.service == service &&
      other.allowedHosts == allowedHosts &&
      other.reason == reason &&
      other.kind == kind &&
      other.status == status &&
      other.expiresAt == expiresAt &&
      other.createdAt == createdAt;

    @override
    int get hashCode =>
        id.hashCode +
        orgId.hashCode +
        botId.hashCode +
        runId.hashCode +
        (conversationId == null ? 0 : conversationId.hashCode) +
        name.hashCode +
        service.hashCode +
        allowedHosts.hashCode +
        reason.hashCode +
        kind.hashCode +
        status.hashCode +
        expiresAt.hashCode +
        createdAt.hashCode;

  factory BotSecretRequest.fromJson(Map<String, dynamic> json) => _$BotSecretRequestFromJson(json);

  Map<String, dynamic> toJson() => _$BotSecretRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum BotSecretRequestStatusEnum {
@JsonValue(r'pending')
pending(r'pending'),
@JsonValue(r'fulfilled')
fulfilled(r'fulfilled'),
@JsonValue(r'declined')
declined(r'declined'),
@JsonValue(r'expired')
expired(r'expired');

const BotSecretRequestStatusEnum(this.value);

final String value;

@override
String toString() => value;
}


