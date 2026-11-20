//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'mail_address.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class MailAddress {
  /// Returns a new [MailAddress] instance.
  MailAddress({

    required  this.id,

    required  this.botId,

    required  this.channelId,

    required  this.localPart,

    required  this.address,

    required  this.status,

    required  this.blockedSenders,

    required  this.notifyNewSenders,

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
    
    name: r'channel_id',
    required: true,
    includeIfNull: false,
  )


  final String channelId;



  @JsonKey(
    
    name: r'local_part',
    required: true,
    includeIfNull: false,
  )


  final String localPart;



  @JsonKey(
    
    name: r'address',
    required: true,
    includeIfNull: false,
  )


  final String address;



  @JsonKey(
    
    name: r'status',
    required: true,
    includeIfNull: false,
  )


  final MailAddressStatusEnum status;



  @JsonKey(
    
    name: r'blocked_senders',
    required: true,
    includeIfNull: false,
  )


  final List<String> blockedSenders;



  @JsonKey(
    
    name: r'notify_new_senders',
    required: true,
    includeIfNull: false,
  )


  final bool notifyNewSenders;



  @JsonKey(
    
    name: r'created_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime createdAt;





    @override
    bool operator ==(Object other) => identical(this, other) || other is MailAddress &&
      other.id == id &&
      other.botId == botId &&
      other.channelId == channelId &&
      other.localPart == localPart &&
      other.address == address &&
      other.status == status &&
      other.blockedSenders == blockedSenders &&
      other.notifyNewSenders == notifyNewSenders &&
      other.createdAt == createdAt;

    @override
    int get hashCode =>
        id.hashCode +
        botId.hashCode +
        channelId.hashCode +
        localPart.hashCode +
        address.hashCode +
        status.hashCode +
        blockedSenders.hashCode +
        notifyNewSenders.hashCode +
        createdAt.hashCode;

  factory MailAddress.fromJson(Map<String, dynamic> json) => _$MailAddressFromJson(json);

  Map<String, dynamic> toJson() => _$MailAddressToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum MailAddressStatusEnum {
@JsonValue(r'active')
active(r'active'),
@JsonValue(r'paused')
paused(r'paused'),
@JsonValue(r'retired')
retired(r'retired');

const MailAddressStatusEnum(this.value);

final String value;

@override
String toString() => value;
}


