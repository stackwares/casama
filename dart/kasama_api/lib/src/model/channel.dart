//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:kasama_api/src/model/channel_kind.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'channel.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Channel {
  /// Returns a new [Channel] instance.
  Channel({

    required  this.id,

    required  this.botId,

    required  this.kind,

    required  this.name,

    required  this.config,

    required  this.allowedSenders,

    required  this.enabled,

    required  this.webhookUrl,

    required  this.verifyToken,

    required  this.lastInboundAt,

    required  this.lastError,

    required  this.createdAt,
  });

  @JsonKey(
    
    name: r'id',
    required: true,
    includeIfNull: false,
  )


  final String id;



  @JsonKey(
    
    name: r'bot_id',
    required: true,
    includeIfNull: false,
  )


  final String botId;



  @JsonKey(
    
    name: r'kind',
    required: true,
    includeIfNull: false,
  )


  final ChannelKind kind;



  @JsonKey(
    
    name: r'name',
    required: true,
    includeIfNull: false,
  )


  final String name;



  @JsonKey(
    
    name: r'config',
    required: true,
    includeIfNull: false,
  )


  final Map<String, Object?> config;



  @JsonKey(
    
    name: r'allowed_senders',
    required: true,
    includeIfNull: false,
  )


  final List<String> allowedSenders;



  @JsonKey(
    
    name: r'enabled',
    required: true,
    includeIfNull: false,
  )


  final bool enabled;



  @JsonKey(
    
    name: r'webhook_url',
    required: true,
    includeIfNull: true,
  )


  final String? webhookUrl;



  @JsonKey(
    
    name: r'verify_token',
    required: true,
    includeIfNull: true,
  )


  final String? verifyToken;



  @JsonKey(
    
    name: r'last_inbound_at',
    required: true,
    includeIfNull: true,
  )


  final DateTime? lastInboundAt;



  @JsonKey(
    
    name: r'last_error',
    required: true,
    includeIfNull: true,
  )


  final String? lastError;



  @JsonKey(
    
    name: r'created_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime createdAt;





    @override
    bool operator ==(Object other) => identical(this, other) || other is Channel &&
      other.id == id &&
      other.botId == botId &&
      other.kind == kind &&
      other.name == name &&
      other.config == config &&
      other.allowedSenders == allowedSenders &&
      other.enabled == enabled &&
      other.webhookUrl == webhookUrl &&
      other.verifyToken == verifyToken &&
      other.lastInboundAt == lastInboundAt &&
      other.lastError == lastError &&
      other.createdAt == createdAt;

    @override
    int get hashCode =>
        id.hashCode +
        botId.hashCode +
        kind.hashCode +
        name.hashCode +
        config.hashCode +
        allowedSenders.hashCode +
        enabled.hashCode +
        (webhookUrl == null ? 0 : webhookUrl.hashCode) +
        (verifyToken == null ? 0 : verifyToken.hashCode) +
        (lastInboundAt == null ? 0 : lastInboundAt.hashCode) +
        (lastError == null ? 0 : lastError.hashCode) +
        createdAt.hashCode;

  factory Channel.fromJson(Map<String, dynamic> json) => _$ChannelFromJson(json);

  Map<String, dynamic> toJson() => _$ChannelToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

