//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/search_result.dart';
import 'package:casama_api/src/model/file_search_result.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'search_response.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SearchResponse {
  /// Returns a new [SearchResponse] instance.
  SearchResponse({

    required  this.query,

    required  this.items,

    required  this.files,

    required  this.filesSearched,
  });

  @JsonKey(
    
    name: r'query',
    required: true,
    includeIfNull: false,
  )


  final String query;



  @JsonKey(
    
    name: r'items',
    required: true,
    includeIfNull: false,
  )


  final List<SearchResult> items;



  @JsonKey(
    
    name: r'files',
    required: true,
    includeIfNull: false,
  )


  final List<FileSearchResult> files;



      /// How many awake computers had their files searched
  @JsonKey(
    
    name: r'files_searched',
    required: true,
    includeIfNull: false,
  )


  final int filesSearched;





    @override
    bool operator ==(Object other) => identical(this, other) || other is SearchResponse &&
      other.query == query &&
      other.items == items &&
      other.files == files &&
      other.filesSearched == filesSearched;

    @override
    int get hashCode =>
        query.hashCode +
        items.hashCode +
        files.hashCode +
        filesSearched.hashCode;

  factory SearchResponse.fromJson(Map<String, dynamic> json) => _$SearchResponseFromJson(json);

  Map<String, dynamic> toJson() => _$SearchResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

