//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/content_author.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'routine_idea.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class RoutineIdea {
  /// Returns a new [RoutineIdea] instance.
  RoutineIdea({

    required  this.id,

    required  this.name,

    required  this.description,

    required  this.category,

    required  this.icon,

    required  this.instructionsMd,

    required  this.scheduleCron,

    required  this.featured,

    required  this.author,
  });

  @JsonKey(
    
    name: r'id',
    required: true,
    includeIfNull: false,
  )


  final String id;



  @JsonKey(
    
    name: r'name',
    required: true,
    includeIfNull: false,
  )


  final String name;



  @JsonKey(
    
    name: r'description',
    required: true,
    includeIfNull: false,
  )


  final String description;



  @JsonKey(
    
    name: r'category',
    required: true,
    includeIfNull: false,
  )


  final RoutineIdeaCategoryEnum category;



      /// Lucide icon name, kebab-case
  @JsonKey(
    
    name: r'icon',
    required: true,
    includeIfNull: false,
  )


  final String icon;



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



  @JsonKey(
    
    name: r'featured',
    required: true,
    includeIfNull: false,
  )


  final bool featured;



  @JsonKey(
    
    name: r'author',
    required: true,
    includeIfNull: false,
  )


  final ContentAuthor author;





    @override
    bool operator ==(Object other) => identical(this, other) || other is RoutineIdea &&
      other.id == id &&
      other.name == name &&
      other.description == description &&
      other.category == category &&
      other.icon == icon &&
      other.instructionsMd == instructionsMd &&
      other.scheduleCron == scheduleCron &&
      other.featured == featured &&
      other.author == author;

    @override
    int get hashCode =>
        id.hashCode +
        name.hashCode +
        description.hashCode +
        category.hashCode +
        icon.hashCode +
        instructionsMd.hashCode +
        scheduleCron.hashCode +
        featured.hashCode +
        author.hashCode;

  factory RoutineIdea.fromJson(Map<String, dynamic> json) => _$RoutineIdeaFromJson(json);

  Map<String, dynamic> toJson() => _$RoutineIdeaToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum RoutineIdeaCategoryEnum {
@JsonValue(r'work')
work(r'work'),
@JsonValue(r'research')
research(r'research'),
@JsonValue(r'build')
build(r'build'),
@JsonValue(r'create')
create(r'create'),
@JsonValue(r'life')
life(r'life');

const RoutineIdeaCategoryEnum(this.value);

final String value;

@override
String toString() => value;
}


