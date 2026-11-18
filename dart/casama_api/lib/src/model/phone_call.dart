//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'phone_call.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PhoneCall {
  /// Returns a new [PhoneCall] instance.
  PhoneCall({

    required  this.id,

    required  this.botId,

    required  this.botName,

    required  this.reason,

    required  this.status,

    required  this.conversationId,

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
    
    name: r'bot_id',
    required: true,
    includeIfNull: false,
  )


  final String botId;



  @JsonKey(
    
    name: r'bot_name',
    required: true,
    includeIfNull: false,
  )


  final String botName;



  @JsonKey(
    
    name: r'reason',
    required: true,
    includeIfNull: false,
  )


  final String reason;



  @JsonKey(
    
    name: r'status',
    required: true,
    includeIfNull: false,
  )


  final PhoneCallStatusEnum status;



  @JsonKey(
    
    name: r'conversation_id',
    required: true,
    includeIfNull: true,
  )


  final String? conversationId;



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
    bool operator ==(Object other) => identical(this, other) || other is PhoneCall &&
      other.id == id &&
      other.botId == botId &&
      other.botName == botName &&
      other.reason == reason &&
      other.status == status &&
      other.conversationId == conversationId &&
      other.expiresAt == expiresAt &&
      other.createdAt == createdAt;

    @override
    int get hashCode =>
        id.hashCode +
        botId.hashCode +
        botName.hashCode +
        reason.hashCode +
        status.hashCode +
        (conversationId == null ? 0 : conversationId.hashCode) +
        expiresAt.hashCode +
        createdAt.hashCode;

  factory PhoneCall.fromJson(Map<String, dynamic> json) => _$PhoneCallFromJson(json);

  Map<String, dynamic> toJson() => _$PhoneCallToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum PhoneCallStatusEnum {
@JsonValue(r'ringing')
ringing(r'ringing'),
@JsonValue(r'answered')
answered(r'answered'),
@JsonValue(r'declined')
declined(r'declined'),
@JsonValue(r'missed')
missed(r'missed'),
@JsonValue(r'cancelled')
cancelled(r'cancelled');

const PhoneCallStatusEnum(this.value);

final String value;

@override
String toString() => value;
}


