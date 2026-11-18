//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'glance_done.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class GlanceDone {
  /// Returns a new [GlanceDone] instance.
  GlanceDone({

    required  this.botId,

    required  this.bot,

    required  this.botAvatar,

    required  this.title,

    required  this.at,

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
    
    name: r'title',
    required: true,
    includeIfNull: false,
  )


  final String title;



  @JsonKey(
    
    name: r'at',
    required: true,
    includeIfNull: false,
  )


  final DateTime at;



  @JsonKey(
    
    name: r'link',
    required: true,
    includeIfNull: false,
  )


  final String link;





    @override
    bool operator ==(Object other) => identical(this, other) || other is GlanceDone &&
      other.botId == botId &&
      other.bot == bot &&
      other.botAvatar == botAvatar &&
      other.title == title &&
      other.at == at &&
      other.link == link;

    @override
    int get hashCode =>
        botId.hashCode +
        bot.hashCode +
        botAvatar.hashCode +
        title.hashCode +
        at.hashCode +
        link.hashCode;

  factory GlanceDone.fromJson(Map<String, dynamic> json) => _$GlanceDoneFromJson(json);

  Map<String, dynamic> toJson() => _$GlanceDoneToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

