//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'glance_brief.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class GlanceBrief {
  /// Returns a new [GlanceBrief] instance.
  GlanceBrief({

    required  this.botId,

    required  this.bot,

    required  this.botAvatar,

    required  this.text,

    required  this.at,

    required  this.nextAt,

    required  this.link,
  });

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
    includeIfNull: true,
  )


  final String? text;



  @JsonKey(
    
    name: r'at',
    required: true,
    includeIfNull: true,
  )


  final DateTime? at;



  @JsonKey(
    
    name: r'next_at',
    required: true,
    includeIfNull: true,
  )


  final DateTime? nextAt;



  @JsonKey(
    
    name: r'link',
    required: true,
    includeIfNull: false,
  )


  final String link;





    @override
    bool operator ==(Object other) => identical(this, other) || other is GlanceBrief &&
      other.botId == botId &&
      other.bot == bot &&
      other.botAvatar == botAvatar &&
      other.text == text &&
      other.at == at &&
      other.nextAt == nextAt &&
      other.link == link;

    @override
    int get hashCode =>
        botId.hashCode +
        bot.hashCode +
        botAvatar.hashCode +
        (text == null ? 0 : text.hashCode) +
        (at == null ? 0 : at.hashCode) +
        (nextAt == null ? 0 : nextAt.hashCode) +
        link.hashCode;

  factory GlanceBrief.fromJson(Map<String, dynamic> json) => _$GlanceBriefFromJson(json);

  Map<String, dynamic> toJson() => _$GlanceBriefToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

