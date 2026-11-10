//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:kasama_api/src/model/create_knowledge_source_request_documents_inner.dart';
import 'package:kasama_api/src/model/create_knowledge_source_request_files_inner.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'create_knowledge_source_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CreateKnowledgeSourceRequest {
  /// Returns a new [CreateKnowledgeSourceRequest] instance.
  CreateKnowledgeSourceRequest({

    required  this.orgId,

     this.botId,

    required  this.kind,

    required  this.name,

     this.files,

     this.url,

     this.maxPages,

     this.repoUrl,

     this.integrationId,

     this.documents,
  });

  @JsonKey(
    
    name: r'org_id',
    required: true,
    includeIfNull: false,
  )


  final String orgId;



  @JsonKey(
    
    name: r'bot_id',
    required: false,
    includeIfNull: false,
  )


  final String? botId;



  @JsonKey(
    
    name: r'kind',
    required: true,
    includeIfNull: false,
  )


  final CreateKnowledgeSourceRequestKindEnum kind;



  @JsonKey(
    
    name: r'name',
    required: true,
    includeIfNull: false,
  )


  final String name;



  @JsonKey(
    
    name: r'files',
    required: false,
    includeIfNull: false,
  )


  final List<CreateKnowledgeSourceRequestFilesInner>? files;



  @JsonKey(
    
    name: r'url',
    required: false,
    includeIfNull: false,
  )


  final String? url;



          // minimum: 1
          // maximum: 200
  @JsonKey(
    
    name: r'max_pages',
    required: false,
    includeIfNull: false,
  )


  final int? maxPages;



  @JsonKey(
    
    name: r'repo_url',
    required: false,
    includeIfNull: false,
  )


  final String? repoUrl;



  @JsonKey(
    
    name: r'integration_id',
    required: false,
    includeIfNull: false,
  )


  final String? integrationId;



  @JsonKey(
    
    name: r'documents',
    required: false,
    includeIfNull: false,
  )


  final List<CreateKnowledgeSourceRequestDocumentsInner>? documents;





    @override
    bool operator ==(Object other) => identical(this, other) || other is CreateKnowledgeSourceRequest &&
      other.orgId == orgId &&
      other.botId == botId &&
      other.kind == kind &&
      other.name == name &&
      other.files == files &&
      other.url == url &&
      other.maxPages == maxPages &&
      other.repoUrl == repoUrl &&
      other.integrationId == integrationId &&
      other.documents == documents;

    @override
    int get hashCode =>
        orgId.hashCode +
        botId.hashCode +
        kind.hashCode +
        name.hashCode +
        files.hashCode +
        url.hashCode +
        maxPages.hashCode +
        repoUrl.hashCode +
        integrationId.hashCode +
        documents.hashCode;

  factory CreateKnowledgeSourceRequest.fromJson(Map<String, dynamic> json) => _$CreateKnowledgeSourceRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CreateKnowledgeSourceRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum CreateKnowledgeSourceRequestKindEnum {
@JsonValue(r'upload')
upload(r'upload'),
@JsonValue(r'website')
website(r'website'),
@JsonValue(r'github')
github(r'github'),
@JsonValue(r'connection')
connection(r'connection');

const CreateKnowledgeSourceRequestKindEnum(this.value);

final String value;

@override
String toString() => value;
}


