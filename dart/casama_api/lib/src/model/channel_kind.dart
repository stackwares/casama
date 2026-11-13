//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:json_annotation/json_annotation.dart';


enum ChannelKind {
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
      imessage(r'imessage'),
      @JsonValue(r'teams')
      teams(r'teams'),
      @JsonValue(r'discord')
      discord(r'discord');

  const ChannelKind(this.value);

  final String value;

  @override
  String toString() => value;
}
