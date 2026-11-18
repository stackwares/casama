//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/page_version.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'bot_page_detail.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class BotPageDetail {
  /// Returns a new [BotPageDetail] instance.
  BotPageDetail({

    required  this.id,

    required  this.botId,

    required  this.title,

    required  this.visibility,

    required  this.version,

    required  this.expiresAt,

    required  this.refreshRoutineId,

    required  this.conversationId,

    required  this.canManage,

    required  this.updatedAt,

    required  this.createdAt,

    required  this.versions,
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
    
    name: r'title',
    required: true,
    includeIfNull: false,
  )


  final String title;



  @JsonKey(
    
    name: r'visibility',
    required: true,
    includeIfNull: false,
  )


  final BotPageDetailVisibilityEnum visibility;



  @JsonKey(
    
    name: r'version',
    required: true,
    includeIfNull: false,
  )


  final int version;



  @JsonKey(
    
    name: r'expires_at',
    required: true,
    includeIfNull: true,
  )


  final DateTime? expiresAt;



  @JsonKey(
    
    name: r'refresh_routine_id',
    required: true,
    includeIfNull: true,
  )


  final String? refreshRoutineId;



  @JsonKey(
    
    name: r'conversation_id',
    required: true,
    includeIfNull: true,
  )


  final String? conversationId;



  @JsonKey(
    
    name: r'can_manage',
    required: true,
    includeIfNull: false,
  )


  final bool canManage;



  @JsonKey(
    
    name: r'updated_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime updatedAt;



  @JsonKey(
    
    name: r'created_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime createdAt;



  @JsonKey(
    
    name: r'versions',
    required: true,
    includeIfNull: false,
  )


  final List<PageVersion> versions;





    @override
    bool operator ==(Object other) => identical(this, other) || other is BotPageDetail &&
      other.id == id &&
      other.botId == botId &&
      other.title == title &&
      other.visibility == visibility &&
      other.version == version &&
      other.expiresAt == expiresAt &&
      other.refreshRoutineId == refreshRoutineId &&
      other.conversationId == conversationId &&
      other.canManage == canManage &&
      other.updatedAt == updatedAt &&
      other.createdAt == createdAt &&
      other.versions == versions;

    @override
    int get hashCode =>
        id.hashCode +
        botId.hashCode +
        title.hashCode +
        visibility.hashCode +
        version.hashCode +
        (expiresAt == null ? 0 : expiresAt.hashCode) +
        (refreshRoutineId == null ? 0 : refreshRoutineId.hashCode) +
        (conversationId == null ? 0 : conversationId.hashCode) +
        canManage.hashCode +
        updatedAt.hashCode +
        createdAt.hashCode +
        versions.hashCode;

  factory BotPageDetail.fromJson(Map<String, dynamic> json) => _$BotPageDetailFromJson(json);

  Map<String, dynamic> toJson() => _$BotPageDetailToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum BotPageDetailVisibilityEnum {
@JsonValue(r'private')
private(r'private'),
@JsonValue(r'workspace')
workspace(r'workspace'),
@JsonValue(r'public')
public(r'public');

const BotPageDetailVisibilityEnum(this.value);

final String value;

@override
String toString() => value;
}


