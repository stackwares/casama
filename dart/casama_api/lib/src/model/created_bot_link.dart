//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'created_bot_link.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CreatedBotLink {
  /// Returns a new [CreatedBotLink] instance.
  CreatedBotLink({

    required  this.id,

    required  this.botId,

    required  this.name,

    required  this.status,

    required  this.peerBotName,

    required  this.remoteUrl,

    required  this.exchanges,

    required  this.createdAt,

    required  this.activatedAt,

    required  this.invite,
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


  final CreatedBotLinkStatusEnum status;



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



  @JsonKey(
    
    name: r'invite',
    required: true,
    includeIfNull: false,
  )


  final String invite;





    @override
    bool operator ==(Object other) => identical(this, other) || other is CreatedBotLink &&
      other.id == id &&
      other.botId == botId &&
      other.name == name &&
      other.status == status &&
      other.peerBotName == peerBotName &&
      other.remoteUrl == remoteUrl &&
      other.exchanges == exchanges &&
      other.createdAt == createdAt &&
      other.activatedAt == activatedAt &&
      other.invite == invite;

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
        (activatedAt == null ? 0 : activatedAt.hashCode) +
        invite.hashCode;

  factory CreatedBotLink.fromJson(Map<String, dynamic> json) => _$CreatedBotLinkFromJson(json);

  Map<String, dynamic> toJson() => _$CreatedBotLinkToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum CreatedBotLinkStatusEnum {
@JsonValue(r'pending')
pending(r'pending'),
@JsonValue(r'active')
active(r'active'),
@JsonValue(r'revoked')
revoked(r'revoked');

const CreatedBotLinkStatusEnum(this.value);

final String value;

@override
String toString() => value;
}


