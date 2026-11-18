//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'glance_routine.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class GlanceRoutine {
  /// Returns a new [GlanceRoutine] instance.
  GlanceRoutine({

    required  this.id,

    required  this.botId,

    required  this.name,

    required  this.bot,

    required  this.botAvatar,

    required  this.nextAt,

    required  this.every,

    required  this.enabled,

    required  this.link,
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
    
    name: r'next_at',
    required: true,
    includeIfNull: true,
  )


  final DateTime? nextAt;



  @JsonKey(
    
    name: r'every',
    required: true,
    includeIfNull: false,
  )


  final String every;



  @JsonKey(
    
    name: r'enabled',
    required: true,
    includeIfNull: false,
  )


  final bool enabled;



  @JsonKey(
    
    name: r'link',
    required: true,
    includeIfNull: false,
  )


  final String link;





    @override
    bool operator ==(Object other) => identical(this, other) || other is GlanceRoutine &&
      other.id == id &&
      other.botId == botId &&
      other.name == name &&
      other.bot == bot &&
      other.botAvatar == botAvatar &&
      other.nextAt == nextAt &&
      other.every == every &&
      other.enabled == enabled &&
      other.link == link;

    @override
    int get hashCode =>
        id.hashCode +
        botId.hashCode +
        name.hashCode +
        bot.hashCode +
        botAvatar.hashCode +
        (nextAt == null ? 0 : nextAt.hashCode) +
        every.hashCode +
        enabled.hashCode +
        link.hashCode;

  factory GlanceRoutine.fromJson(Map<String, dynamic> json) => _$GlanceRoutineFromJson(json);

  Map<String, dynamic> toJson() => _$GlanceRoutineToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

