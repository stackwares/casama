//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'create_knowledge_source_request_files_inner.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CreateKnowledgeSourceRequestFilesInner {
  /// Returns a new [CreateKnowledgeSourceRequestFilesInner] instance.
  CreateKnowledgeSourceRequestFilesInner({

    required  this.name,

    required  this.contentBase64,
  });

  @JsonKey(
    
    name: r'name',
    required: true,
    includeIfNull: false,
  )


  final String name;



  @JsonKey(
    
    name: r'content_base64',
    required: true,
    includeIfNull: false,
  )


  final String contentBase64;





    @override
    bool operator ==(Object other) => identical(this, other) || other is CreateKnowledgeSourceRequestFilesInner &&
      other.name == name &&
      other.contentBase64 == contentBase64;

    @override
    int get hashCode =>
        name.hashCode +
        contentBase64.hashCode;

  factory CreateKnowledgeSourceRequestFilesInner.fromJson(Map<String, dynamic> json) => _$CreateKnowledgeSourceRequestFilesInnerFromJson(json);

  Map<String, dynamic> toJson() => _$CreateKnowledgeSourceRequestFilesInnerToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

