//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'glance_need.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class GlanceNeed {
  /// Returns a new [GlanceNeed] instance.
  GlanceNeed({

    required  this.kind,

    required  this.id,

    required  this.botId,

    required  this.bot,

    required  this.botAvatar,

    required  this.text,

    required  this.risk,

    required  this.urgent,

    required  this.createdAt,

    required  this.link,
  });

  @JsonKey(
    
    name: r'kind',
    required: true,
    includeIfNull: false,
  )


  final GlanceNeedKindEnum kind;



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
    
    name: r'bot',
    required: true,
    includeIfNull: false,
  )


  final String bot;



  @JsonKey(
    
    name: r'bot_avatar',
    required: true,
    includeIfNull: false,
  )


  final String botAvatar;



  @JsonKey(
    
    name: r'text',
    required: true,
    includeIfNull: false,
  )


  final String text;



  @JsonKey(
    
    name: r'risk',
    required: true,
    includeIfNull: true,
  )


  final GlanceNeedRiskEnum? risk;



  @JsonKey(
    
    name: r'urgent',
    required: true,
    includeIfNull: false,
  )


  final bool urgent;



  @JsonKey(
    
    name: r'created_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime createdAt;



  @JsonKey(
    
    name: r'link',
    required: true,
    includeIfNull: false,
  )


  final String link;





    @override
    bool operator ==(Object other) => identical(this, other) || other is GlanceNeed &&
      other.kind == kind &&
      other.id == id &&
      other.botId == botId &&
      other.bot == bot &&
      other.botAvatar == botAvatar &&
      other.text == text &&
      other.risk == risk &&
      other.urgent == urgent &&
      other.createdAt == createdAt &&
      other.link == link;

    @override
    int get hashCode =>
        kind.hashCode +
        id.hashCode +
        botId.hashCode +
        bot.hashCode +
        botAvatar.hashCode +
        text.hashCode +
        (risk == null ? 0 : risk.hashCode) +
        urgent.hashCode +
        createdAt.hashCode +
        link.hashCode;

  factory GlanceNeed.fromJson(Map<String, dynamic> json) => _$GlanceNeedFromJson(json);

  Map<String, dynamic> toJson() => _$GlanceNeedToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum GlanceNeedKindEnum {
@JsonValue(r'approval')
approval(r'approval'),
@JsonValue(r'takeover')
takeover(r'takeover'),
@JsonValue(r'suggestion')
suggestion(r'suggestion');

const GlanceNeedKindEnum(this.value);

final String value;

@override
String toString() => value;
}



enum GlanceNeedRiskEnum {
@JsonValue(r'low')
low(r'low'),
@JsonValue(r'medium')
medium(r'medium'),
@JsonValue(r'high')
high(r'high');

const GlanceNeedRiskEnum(this.value);

final String value;

@override
String toString() => value;
}


