//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:kasama_api/src/model/visibility.dart';
import 'package:kasama_api/src/model/autonomy.dart';
import 'package:kasama_api/src/model/bot_budget.dart';
import 'package:kasama_api/src/model/model_policy.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'bot.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Bot {
  /// Returns a new [Bot] instance.
  Bot({

    required  this.id,

    required  this.orgId,

    required  this.name,

    required  this.avatarUrl,

    required  this.personaMd,

    required  this.modelPolicy,

    required  this.autonomy,

    required  this.visibility,

    required  this.budget,

    required  this.status,

    required  this.defaultComputerId,

    required  this.folderId,

    required  this.sortKey,

    required  this.archivedAt,

    required  this.createdAt,
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
    
    name: r'name',
    required: true,
    includeIfNull: false,
  )


  final String name;



  @JsonKey(
    
    name: r'avatar_url',
    required: true,
    includeIfNull: true,
  )


  final String? avatarUrl;



  @JsonKey(
    
    name: r'persona_md',
    required: true,
    includeIfNull: false,
  )


  final String personaMd;



  @JsonKey(
    
    name: r'model_policy',
    required: true,
    includeIfNull: false,
  )


  final ModelPolicy modelPolicy;



  @JsonKey(
    
    name: r'autonomy',
    required: true,
    includeIfNull: false,
  )


  final Autonomy autonomy;



  @JsonKey(
    
    name: r'visibility',
    required: true,
    includeIfNull: false,
  )


  final Visibility visibility;



  @JsonKey(
    
    name: r'budget',
    required: true,
    includeIfNull: false,
  )


  final BotBudget budget;



  @JsonKey(
    
    name: r'status',
    required: true,
    includeIfNull: false,
  )


  final BotStatusEnum status;



      /// Its computer; null = its private computer, else the team computer
  @JsonKey(
    
    name: r'default_computer_id',
    required: true,
    includeIfNull: true,
  )


  final String? defaultComputerId;



      /// Its sidebar folder (bot_folders)
  @JsonKey(
    
    name: r'folder_id',
    required: true,
    includeIfNull: true,
  )


  final String? folderId;



      /// Order within its folder
  @JsonKey(
    
    name: r'sort_key',
    required: true,
    includeIfNull: false,
  )


  final num sortKey;



  @JsonKey(
    
    name: r'archived_at',
    required: true,
    includeIfNull: true,
  )


  final DateTime? archivedAt;



  @JsonKey(
    
    name: r'created_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime createdAt;





    @override
    bool operator ==(Object other) => identical(this, other) || other is Bot &&
      other.id == id &&
      other.orgId == orgId &&
      other.name == name &&
      other.avatarUrl == avatarUrl &&
      other.personaMd == personaMd &&
      other.modelPolicy == modelPolicy &&
      other.autonomy == autonomy &&
      other.visibility == visibility &&
      other.budget == budget &&
      other.status == status &&
      other.defaultComputerId == defaultComputerId &&
      other.folderId == folderId &&
      other.sortKey == sortKey &&
      other.archivedAt == archivedAt &&
      other.createdAt == createdAt;

    @override
    int get hashCode =>
        id.hashCode +
        orgId.hashCode +
        name.hashCode +
        (avatarUrl == null ? 0 : avatarUrl.hashCode) +
        personaMd.hashCode +
        modelPolicy.hashCode +
        autonomy.hashCode +
        visibility.hashCode +
        budget.hashCode +
        status.hashCode +
        (defaultComputerId == null ? 0 : defaultComputerId.hashCode) +
        (folderId == null ? 0 : folderId.hashCode) +
        sortKey.hashCode +
        (archivedAt == null ? 0 : archivedAt.hashCode) +
        createdAt.hashCode;

  factory Bot.fromJson(Map<String, dynamic> json) => _$BotFromJson(json);

  Map<String, dynamic> toJson() => _$BotToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum BotStatusEnum {
@JsonValue(r'idle')
idle(r'idle'),
@JsonValue(r'working')
working(r'working'),
@JsonValue(r'waiting')
waiting(r'waiting'),
@JsonValue(r'disabled')
disabled(r'disabled');

const BotStatusEnum(this.value);

final String value;

@override
String toString() => value;
}


