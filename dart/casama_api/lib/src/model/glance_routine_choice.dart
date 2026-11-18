//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'glance_routine_choice.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class GlanceRoutineChoice {
  /// Returns a new [GlanceRoutineChoice] instance.
  GlanceRoutineChoice({

    required  this.id,

    required  this.botId,

    required  this.name,

    required  this.bot,

    required  this.enabled,
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
    
    name: r'enabled',
    required: true,
    includeIfNull: false,
  )


  final bool enabled;





    @override
    bool operator ==(Object other) => identical(this, other) || other is GlanceRoutineChoice &&
      other.id == id &&
      other.botId == botId &&
      other.name == name &&
      other.bot == bot &&
      other.enabled == enabled;

    @override
    int get hashCode =>
        id.hashCode +
        botId.hashCode +
        name.hashCode +
        bot.hashCode +
        enabled.hashCode;

  factory GlanceRoutineChoice.fromJson(Map<String, dynamic> json) => _$GlanceRoutineChoiceFromJson(json);

  Map<String, dynamic> toJson() => _$GlanceRoutineChoiceToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

