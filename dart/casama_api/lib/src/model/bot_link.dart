//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'bot_link.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class BotLink {
  /// Returns a new [BotLink] instance.
  BotLink({

    required  this.id,

    required  this.botId,

    required  this.name,

    required  this.status,

    required  this.peerBotName,

    required  this.remoteUrl,

    required  this.exchanges,

    required  this.createdAt,

    required  this.activatedAt,
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


  final BotLinkStatusEnum status;



  @JsonKey(
    
    name: r'peer_bot_name',
    required: true,
    includeIfNull: true,
  )


  final String? peerBotName;



      /// The other Casama server, when the contact is on another one
  @JsonKey(
    
    name: r'remote_url',
    required: true,
    includeIfNull: true,
  )


  final String? remoteUrl;



  @JsonKey(
    
    name: r'exchanges',
    required: true,
    includeIfNull: false,
  )


  final int exchanges;



  @JsonKey(
    
    name: r'created_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime createdAt;



  @JsonKey(
    
    name: r'activated_at',
    required: true,
    includeIfNull: true,
  )


  final DateTime? activatedAt;





    @override
    bool operator ==(Object other) => identical(this, other) || other is BotLink &&
      other.id == id &&
      other.botId == botId &&
      other.name == name &&
      other.status == status &&
      other.peerBotName == peerBotName &&
      other.remoteUrl == remoteUrl &&
      other.exchanges == exchanges &&
      other.createdAt == createdAt &&
      other.activatedAt == activatedAt;

    @override
    int get hashCode =>
        id.hashCode +
        botId.hashCode +
        name.hashCode +
        status.hashCode +
        (peerBotName == null ? 0 : peerBotName.hashCode) +
        (remoteUrl == null ? 0 : remoteUrl.hashCode) +
        exchanges.hashCode +
        createdAt.hashCode +
        (activatedAt == null ? 0 : activatedAt.hashCode);

  factory BotLink.fromJson(Map<String, dynamic> json) => _$BotLinkFromJson(json);

  Map<String, dynamic> toJson() => _$BotLinkToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum BotLinkStatusEnum {
@JsonValue(r'pending')
pending(r'pending'),
@JsonValue(r'active')
active(r'active'),
@JsonValue(r'revoked')
revoked(r'revoked');

const BotLinkStatusEnum(this.value);

final String value;

@override
String toString() => value;
}


