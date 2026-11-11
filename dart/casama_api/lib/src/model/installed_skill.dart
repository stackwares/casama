//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'installed_skill.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class InstalledSkill {
  /// Returns a new [InstalledSkill] instance.
  InstalledSkill({

    required  this.id,

    required  this.orgId,

    required  this.botId,

    required  this.name,

    required  this.description,

    required  this.source_,

    required  this.sourceRef,

    required  this.category,

    required  this.fileCount,

    required  this.updatedAt,
  });

  @JsonKey(
    
    name: r'id',
    required: true,
    includeIfNull: false,
  )


  final String id;



  @JsonKey(
    
    name: r'org_id',
    required: true,
    includeIfNull: false,
  )


  final String orgId;



  @JsonKey(
    
    name: r'bot_id',
    required: true,
    includeIfNull: true,
  )


  final String? botId;



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
    
    name: r'source',
    required: true,
    includeIfNull: false,
  )


  final InstalledSkillSource_Enum source_;



  @JsonKey(
    
    name: r'source_ref',
    required: true,
    includeIfNull: false,
  )


  final Map<String, Object?> sourceRef;



  @JsonKey(
    
    name: r'category',
    required: true,
    includeIfNull: true,
  )


  final String? category;



  @JsonKey(
    
    name: r'file_count',
    required: true,
    includeIfNull: false,
  )


  final int fileCount;



  @JsonKey(
    
    name: r'updated_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime updatedAt;





    @override
    bool operator ==(Object other) => identical(this, other) || other is InstalledSkill &&
      other.id == id &&
      other.orgId == orgId &&
      other.botId == botId &&
      other.name == name &&
      other.description == description &&
      other.source_ == source_ &&
      other.sourceRef == sourceRef &&
      other.category == category &&
      other.fileCount == fileCount &&
      other.updatedAt == updatedAt;

    @override
    int get hashCode =>
        id.hashCode +
        orgId.hashCode +
        (botId == null ? 0 : botId.hashCode) +
        name.hashCode +
        description.hashCode +
        source_.hashCode +
        sourceRef.hashCode +
        (category == null ? 0 : category.hashCode) +
        fileCount.hashCode +
        updatedAt.hashCode;

  factory InstalledSkill.fromJson(Map<String, dynamic> json) => _$InstalledSkillFromJson(json);

  Map<String, dynamic> toJson() => _$InstalledSkillToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum InstalledSkillSource_Enum {
@JsonValue(r'manual')
manual(r'manual'),
@JsonValue(r'catalog')
catalog(r'catalog'),
@JsonValue(r'github')
github(r'github'),
@JsonValue(r'bot')
bot(r'bot'),
@JsonValue(r'gallery')
gallery(r'gallery');

const InstalledSkillSource_Enum(this.value);

final String value;

@override
String toString() => value;
}


