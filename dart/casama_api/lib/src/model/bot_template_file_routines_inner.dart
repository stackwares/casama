//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'bot_template_file_routines_inner.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class BotTemplateFileRoutinesInner {
  /// Returns a new [BotTemplateFileRoutinesInner] instance.
  BotTemplateFileRoutinesInner({

    required  this.name,

    required  this.instructionsMd,

    required  this.scheduleCron,
  });

  @JsonKey(
    
    name: r'name',
    required: true,
    includeIfNull: false,
  )


  final String name;



  @JsonKey(
    
    name: r'instructions_md',
    required: true,
    includeIfNull: false,
  )


  final String instructionsMd;



  @JsonKey(
    
    name: r'schedule_cron',
    required: true,
    includeIfNull: false,
  )


  final String scheduleCron;





    @override
    bool operator ==(Object other) => identical(this, other) || other is BotTemplateFileRoutinesInner &&
      other.name == name &&
      other.instructionsMd == instructionsMd &&
      other.scheduleCron == scheduleCron;

    @override
    int get hashCode =>
        name.hashCode +
        instructionsMd.hashCode +
        scheduleCron.hashCode;

  factory BotTemplateFileRoutinesInner.fromJson(Map<String, dynamic> json) => _$BotTemplateFileRoutinesInnerFromJson(json);

  Map<String, dynamic> toJson() => _$BotTemplateFileRoutinesInnerToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

