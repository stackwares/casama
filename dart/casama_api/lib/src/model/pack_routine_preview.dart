//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'pack_routine_preview.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PackRoutinePreview {
  /// Returns a new [PackRoutinePreview] instance.
  PackRoutinePreview({

    required  this.id,

    required  this.name,

    required  this.description,

    required  this.instructionsMd,

    required  this.scheduleCron,

    required  this.bot,

    required  this.runsPerWeek,
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



      /// The pack bot it runs on, by id
  @JsonKey(
    
    name: r'bot',
    required: true,
    includeIfNull: true,
  )


  final String? bot;



  @JsonKey(
    
    name: r'runs_per_week',
    required: true,
    includeIfNull: false,
  )


  final num runsPerWeek;





    @override
    bool operator ==(Object other) => identical(this, other) || other is PackRoutinePreview &&
      other.id == id &&
      other.name == name &&
      other.description == description &&
      other.instructionsMd == instructionsMd &&
      other.scheduleCron == scheduleCron &&
      other.bot == bot &&
      other.runsPerWeek == runsPerWeek;

    @override
    int get hashCode =>
        id.hashCode +
        name.hashCode +
        description.hashCode +
        instructionsMd.hashCode +
        scheduleCron.hashCode +
        (bot == null ? 0 : bot.hashCode) +
        runsPerWeek.hashCode;

  factory PackRoutinePreview.fromJson(Map<String, dynamic> json) => _$PackRoutinePreviewFromJson(json);

  Map<String, dynamic> toJson() => _$PackRoutinePreviewToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

