//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'create_knowledge_source_request_documents_inner.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CreateKnowledgeSourceRequestDocumentsInner {
  /// Returns a new [CreateKnowledgeSourceRequestDocumentsInner] instance.
  CreateKnowledgeSourceRequestDocumentsInner({

    required  this.tool,

     this.args,

    required  this.title,

     this.url,
  });

  @JsonKey(
    
    name: r'tool',
    required: true,
    includeIfNull: false,
  )


  final String tool;



  @JsonKey(
    
    name: r'args',
    required: false,
    includeIfNull: false,
  )


  final Map<String, Object?>? args;



  @JsonKey(
    
    name: r'title',
    required: true,
    includeIfNull: false,
  )


  final String title;



  @JsonKey(
    
    name: r'url',
    required: false,
    includeIfNull: false,
  )


  final String? url;





    @override
    bool operator ==(Object other) => identical(this, other) || other is CreateKnowledgeSourceRequestDocumentsInner &&
      other.tool == tool &&
      other.args == args &&
      other.title == title &&
      other.url == url;

    @override
    int get hashCode =>
        tool.hashCode +
        args.hashCode +
        title.hashCode +
        url.hashCode;

  factory CreateKnowledgeSourceRequestDocumentsInner.fromJson(Map<String, dynamic> json) => _$CreateKnowledgeSourceRequestDocumentsInnerFromJson(json);

  Map<String, dynamic> toJson() => _$CreateKnowledgeSourceRequestDocumentsInnerToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

