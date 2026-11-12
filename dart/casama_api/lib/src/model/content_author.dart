//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'content_author.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ContentAuthor {
  /// Returns a new [ContentAuthor] instance.
  ContentAuthor({

    required  this.name,

     this.url,
  });

  @JsonKey(
    
    name: r'name',
    required: true,
    includeIfNull: false,
  )


  final String name;



  @JsonKey(
    
    name: r'url',
    required: false,
    includeIfNull: false,
  )


  final String? url;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ContentAuthor &&
      other.name == name &&
      other.url == url;

    @override
    int get hashCode =>
        name.hashCode +
        url.hashCode;

  factory ContentAuthor.fromJson(Map<String, dynamic> json) => _$ContentAuthorFromJson(json);

  Map<String, dynamic> toJson() => _$ContentAuthorToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

