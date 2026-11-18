//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'pack_bot_preview_knowledge_inner.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PackBotPreviewKnowledgeInner {
  /// Returns a new [PackBotPreviewKnowledgeInner] instance.
  PackBotPreviewKnowledgeInner({

    required  this.kind,

    required  this.name,

    required  this.url,

    required  this.maxPages,
  });

  @JsonKey(
    
    name: r'kind',
    required: true,
    includeIfNull: false,
  )


  final PackBotPreviewKnowledgeInnerKindEnum kind;



  @JsonKey(
    
    name: r'name',
    required: true,
    includeIfNull: false,
  )


  final String name;



  @JsonKey(
    
    name: r'url',
    required: true,
    includeIfNull: false,
  )


  final String url;



  @JsonKey(
    
    name: r'max_pages',
    required: true,
    includeIfNull: false,
  )


  final int maxPages;





    @override
    bool operator ==(Object other) => identical(this, other) || other is PackBotPreviewKnowledgeInner &&
      other.kind == kind &&
      other.name == name &&
      other.url == url &&
      other.maxPages == maxPages;

    @override
    int get hashCode =>
        kind.hashCode +
        name.hashCode +
        url.hashCode +
        maxPages.hashCode;

  factory PackBotPreviewKnowledgeInner.fromJson(Map<String, dynamic> json) => _$PackBotPreviewKnowledgeInnerFromJson(json);

  Map<String, dynamic> toJson() => _$PackBotPreviewKnowledgeInnerToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum PackBotPreviewKnowledgeInnerKindEnum {
@JsonValue(r'website')
website(r'website'),
@JsonValue(r'github')
github(r'github');

const PackBotPreviewKnowledgeInnerKindEnum(this.value);

final String value;

@override
String toString() => value;
}


