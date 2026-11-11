//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'file_search_result.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class FileSearchResult {
  /// Returns a new [FileSearchResult] instance.
  FileSearchResult({

    required  this.computerId,

    required  this.computerName,

    required  this.path,

    required  this.match,
  });

  @JsonKey(
    
    name: r'computer_id',
    required: true,
    includeIfNull: false,
  )


  final String computerId;



  @JsonKey(
    
    name: r'computer_name',
    required: true,
    includeIfNull: false,
  )


  final String computerName;



  @JsonKey(
    
    name: r'path',
    required: true,
    includeIfNull: false,
  )


  final String path;



  @JsonKey(
    
    name: r'match',
    required: true,
    includeIfNull: false,
  )


  final FileSearchResultMatchEnum match;





    @override
    bool operator ==(Object other) => identical(this, other) || other is FileSearchResult &&
      other.computerId == computerId &&
      other.computerName == computerName &&
      other.path == path &&
      other.match == match;

    @override
    int get hashCode =>
        computerId.hashCode +
        computerName.hashCode +
        path.hashCode +
        match.hashCode;

  factory FileSearchResult.fromJson(Map<String, dynamic> json) => _$FileSearchResultFromJson(json);

  Map<String, dynamic> toJson() => _$FileSearchResultToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum FileSearchResultMatchEnum {
@JsonValue(r'name')
name(r'name'),
@JsonValue(r'content')
content(r'content');

const FileSearchResultMatchEnum(this.value);

final String value;

@override
String toString() => value;
}


