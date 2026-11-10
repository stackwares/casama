//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'knowledge_source.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class KnowledgeSource {
  /// Returns a new [KnowledgeSource] instance.
  KnowledgeSource({

    required  this.id,

    required  this.botId,

    required  this.kind,

    required  this.name,

    required  this.config,

    required  this.status,

    required  this.error,

    required  this.documents,

    required  this.chunks,

    required  this.lastSyncedAt,

    required  this.createdAt,
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
    includeIfNull: true,
  )


  final String? botId;



  @JsonKey(
    
    name: r'kind',
    required: true,
    includeIfNull: false,
  )


  final KnowledgeSourceKindEnum kind;



  @JsonKey(
    
    name: r'name',
    required: true,
    includeIfNull: false,
  )


  final String name;



  @JsonKey(
    
    name: r'config',
    required: true,
    includeIfNull: false,
  )


  final Map<String, Object?> config;



  @JsonKey(
    
    name: r'status',
    required: true,
    includeIfNull: false,
  )


  final KnowledgeSourceStatusEnum status;



  @JsonKey(
    
    name: r'error',
    required: true,
    includeIfNull: true,
  )


  final String? error;



  @JsonKey(
    
    name: r'documents',
    required: true,
    includeIfNull: false,
  )


  final int documents;



  @JsonKey(
    
    name: r'chunks',
    required: true,
    includeIfNull: false,
  )


  final int chunks;



  @JsonKey(
    
    name: r'last_synced_at',
    required: true,
    includeIfNull: true,
  )


  final DateTime? lastSyncedAt;



  @JsonKey(
    
    name: r'created_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime createdAt;





    @override
    bool operator ==(Object other) => identical(this, other) || other is KnowledgeSource &&
      other.id == id &&
      other.botId == botId &&
      other.kind == kind &&
      other.name == name &&
      other.config == config &&
      other.status == status &&
      other.error == error &&
      other.documents == documents &&
      other.chunks == chunks &&
      other.lastSyncedAt == lastSyncedAt &&
      other.createdAt == createdAt;

    @override
    int get hashCode =>
        id.hashCode +
        (botId == null ? 0 : botId.hashCode) +
        kind.hashCode +
        name.hashCode +
        config.hashCode +
        status.hashCode +
        (error == null ? 0 : error.hashCode) +
        documents.hashCode +
        chunks.hashCode +
        (lastSyncedAt == null ? 0 : lastSyncedAt.hashCode) +
        createdAt.hashCode;

  factory KnowledgeSource.fromJson(Map<String, dynamic> json) => _$KnowledgeSourceFromJson(json);

  Map<String, dynamic> toJson() => _$KnowledgeSourceToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum KnowledgeSourceKindEnum {
@JsonValue(r'upload')
upload(r'upload'),
@JsonValue(r'website')
website(r'website'),
@JsonValue(r'github')
github(r'github'),
@JsonValue(r'connection')
connection(r'connection');

const KnowledgeSourceKindEnum(this.value);

final String value;

@override
String toString() => value;
}



enum KnowledgeSourceStatusEnum {
@JsonValue(r'pending')
pending(r'pending'),
@JsonValue(r'syncing')
syncing(r'syncing'),
@JsonValue(r'ready')
ready(r'ready'),
@JsonValue(r'error')
error(r'error');

const KnowledgeSourceStatusEnum(this.value);

final String value;

@override
String toString() => value;
}


