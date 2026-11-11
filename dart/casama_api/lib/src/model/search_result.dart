//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/search_kind.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'search_result.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SearchResult {
  /// Returns a new [SearchResult] instance.
  SearchResult({

    required  this.kind,

    required  this.id,

    required  this.title,

    required  this.snippet,

    required  this.botId,

    required  this.conversationId,

    required  this.createdAt,
  });

  @JsonKey(
    
    name: r'kind',
    required: true,
    includeIfNull: false,
  )


  final SearchKind kind;



  @JsonKey(
    
    name: r'id',
    required: true,
    includeIfNull: false,
  )


  final String id;



  @JsonKey(
    
    name: r'title',
    required: true,
    includeIfNull: false,
  )


  final String title;



      /// Matching text; matches are wrapped in « »
  @JsonKey(
    
    name: r'snippet',
    required: true,
    includeIfNull: false,
  )


  final String snippet;



  @JsonKey(
    
    name: r'bot_id',
    required: true,
    includeIfNull: true,
  )


  final String? botId;



  @JsonKey(
    
    name: r'conversation_id',
    required: true,
    includeIfNull: true,
  )


  final String? conversationId;



  @JsonKey(
    
    name: r'created_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime createdAt;





    @override
    bool operator ==(Object other) => identical(this, other) || other is SearchResult &&
      other.kind == kind &&
      other.id == id &&
      other.title == title &&
      other.snippet == snippet &&
      other.botId == botId &&
      other.conversationId == conversationId &&
      other.createdAt == createdAt;

    @override
    int get hashCode =>
        kind.hashCode +
        id.hashCode +
        title.hashCode +
        snippet.hashCode +
        (botId == null ? 0 : botId.hashCode) +
        (conversationId == null ? 0 : conversationId.hashCode) +
        createdAt.hashCode;

  factory SearchResult.fromJson(Map<String, dynamic> json) => _$SearchResultFromJson(json);

  Map<String, dynamic> toJson() => _$SearchResultToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

