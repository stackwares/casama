//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'message_trigger_config.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class MessageTriggerConfig {
  /// Returns a new [MessageTriggerConfig] instance.
  MessageTriggerConfig({

     this.channelId,

     this.channelKind,

     this.sender,

     this.subjectMatch,

     this.textMatch,
  });

  @JsonKey(
    
    name: r'channel_id',
    required: false,
    includeIfNull: false,
  )


  final String? channelId;



  @JsonKey(
    
    name: r'channel_kind',
    required: false,
    includeIfNull: false,
  )


  final MessageTriggerConfigChannelKindEnum? channelKind;



      /// An address or id; *@domain for email
  @JsonKey(
    
    name: r'sender',
    required: false,
    includeIfNull: false,
  )


  final String? sender;



  @JsonKey(
    
    name: r'subject_match',
    required: false,
    includeIfNull: false,
  )


  final String? subjectMatch;



  @JsonKey(
    
    name: r'text_match',
    required: false,
    includeIfNull: false,
  )


  final String? textMatch;





    @override
    bool operator ==(Object other) => identical(this, other) || other is MessageTriggerConfig &&
      other.channelId == channelId &&
      other.channelKind == channelKind &&
      other.sender == sender &&
      other.subjectMatch == subjectMatch &&
      other.textMatch == textMatch;

    @override
    int get hashCode =>
        channelId.hashCode +
        channelKind.hashCode +
        sender.hashCode +
        subjectMatch.hashCode +
        textMatch.hashCode;

  factory MessageTriggerConfig.fromJson(Map<String, dynamic> json) => _$MessageTriggerConfigFromJson(json);

  Map<String, dynamic> toJson() => _$MessageTriggerConfigToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum MessageTriggerConfigChannelKindEnum {
@JsonValue(r'telegram')
telegram(r'telegram'),
@JsonValue(r'email')
email(r'email'),
@JsonValue(r'sms')
sms(r'sms'),
@JsonValue(r'slack')
slack(r'slack'),
@JsonValue(r'whatsapp')
whatsapp(r'whatsapp'),
@JsonValue(r'messenger')
messenger(r'messenger'),
@JsonValue(r'feishu')
feishu(r'feishu'),
@JsonValue(r'imessage')
imessage(r'imessage');

const MessageTriggerConfigChannelKindEnum(this.value);

final String value;

@override
String toString() => value;
}


