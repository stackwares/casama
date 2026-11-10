//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:kasama_api/src/model/bot_template_file_routines_inner.dart';
import 'package:kasama_api/src/model/bot_template_file_skills_inner.dart';
import 'package:kasama_api/src/model/bot_template_file_memories_inner.dart';
import 'package:kasama_api/src/model/bot_template_file_connections_inner.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'bot_template_file.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class BotTemplateFile {
  /// Returns a new [BotTemplateFile] instance.
  BotTemplateFile({

    required  this.format,

    required  this.version,

    required  this.name,

     this.description,

    required  this.personaMd,

    required  this.autonomy,

     this.avatar,

     this.skills,

     this.routines,

     this.connections,

     this.memories,
  });

  @JsonKey(
    
    name: r'format',
    required: true,
    includeIfNull: false,
  )


  final BotTemplateFileFormatEnum format;



      /// Format version (1)
          // minimum: 1
          // maximum: 1
  @JsonKey(
    
    name: r'version',
    required: true,
    includeIfNull: false,
  )


  final int version;



  @JsonKey(
    
    name: r'name',
    required: true,
    includeIfNull: false,
  )


  final String name;



  @JsonKey(
    
    name: r'description',
    required: false,
    includeIfNull: false,
  )


  final String? description;



  @JsonKey(
    
    name: r'persona_md',
    required: true,
    includeIfNull: false,
  )


  final String personaMd;



  @JsonKey(
    
    name: r'autonomy',
    required: true,
    includeIfNull: false,
  )


  final BotTemplateFileAutonomyEnum autonomy;



  @JsonKey(
    
    name: r'avatar',
    required: false,
    includeIfNull: false,
  )


  final String? avatar;



  @JsonKey(
    
    name: r'skills',
    required: false,
    includeIfNull: false,
  )


  final List<BotTemplateFileSkillsInner>? skills;



  @JsonKey(
    
    name: r'routines',
    required: false,
    includeIfNull: false,
  )


  final List<BotTemplateFileRoutinesInner>? routines;



      /// Services to connect after importing (names only, no credentials)
  @JsonKey(
    
    name: r'connections',
    required: false,
    includeIfNull: false,
  )


  final List<BotTemplateFileConnectionsInner>? connections;



  @JsonKey(
    
    name: r'memories',
    required: false,
    includeIfNull: false,
  )


  final List<BotTemplateFileMemoriesInner>? memories;





    @override
    bool operator ==(Object other) => identical(this, other) || other is BotTemplateFile &&
      other.format == format &&
      other.version == version &&
      other.name == name &&
      other.description == description &&
      other.personaMd == personaMd &&
      other.autonomy == autonomy &&
      other.avatar == avatar &&
      other.skills == skills &&
      other.routines == routines &&
      other.connections == connections &&
      other.memories == memories;

    @override
    int get hashCode =>
        format.hashCode +
        version.hashCode +
        name.hashCode +
        description.hashCode +
        personaMd.hashCode +
        autonomy.hashCode +
        (avatar == null ? 0 : avatar.hashCode) +
        skills.hashCode +
        routines.hashCode +
        connections.hashCode +
        memories.hashCode;

  factory BotTemplateFile.fromJson(Map<String, dynamic> json) => _$BotTemplateFileFromJson(json);

  Map<String, dynamic> toJson() => _$BotTemplateFileToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum BotTemplateFileFormatEnum {
@JsonValue(r'kasama.bot')
kasamaPeriodBot(r'kasama.bot');

const BotTemplateFileFormatEnum(this.value);

final String value;

@override
String toString() => value;
}



enum BotTemplateFileAutonomyEnum {
@JsonValue(r'ask_always')
askAlways(r'ask_always'),
@JsonValue(r'ask_risky')
askRisky(r'ask_risky'),
@JsonValue(r'autonomous')
autonomous(r'autonomous');

const BotTemplateFileAutonomyEnum(this.value);

final String value;

@override
String toString() => value;
}


