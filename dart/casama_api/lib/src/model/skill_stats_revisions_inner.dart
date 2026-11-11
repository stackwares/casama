//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'skill_stats_revisions_inner.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SkillStatsRevisionsInner {
  /// Returns a new [SkillStatsRevisionsInner] instance.
  SkillStatsRevisionsInner({

    required  this.id,

    required  this.description,

    required  this.bodyMd,

    required  this.byBot,

    required  this.createdAt,
  });

  @JsonKey(
    
    name: r'id',
    required: true,
    includeIfNull: false,
  )


  final String id;



  @JsonKey(
    
    name: r'description',
    required: true,
    includeIfNull: false,
  )


  final String description;



  @JsonKey(
    
    name: r'body_md',
    required: true,
    includeIfNull: false,
  )


  final String bodyMd;



  @JsonKey(
    
    name: r'by_bot',
    required: true,
    includeIfNull: false,
  )


  final bool byBot;



  @JsonKey(
    
    name: r'created_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime createdAt;





    @override
    bool operator ==(Object other) => identical(this, other) || other is SkillStatsRevisionsInner &&
      other.id == id &&
      other.description == description &&
      other.bodyMd == bodyMd &&
      other.byBot == byBot &&
      other.createdAt == createdAt;

    @override
    int get hashCode =>
        id.hashCode +
        description.hashCode +
        bodyMd.hashCode +
        byBot.hashCode +
        createdAt.hashCode;

  factory SkillStatsRevisionsInner.fromJson(Map<String, dynamic> json) => _$SkillStatsRevisionsInnerFromJson(json);

  Map<String, dynamic> toJson() => _$SkillStatsRevisionsInnerToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

