//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'create_highlight_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CreateHighlightRequest {
  /// Returns a new [CreateHighlightRequest] instance.
  CreateHighlightRequest({

    required  this.orgId,

    required  this.url,

     this.title,

    required  this.text,

     this.prefix,

     this.suffix,

     this.note,
  });

  @JsonKey(
    
    name: r'org_id',
    required: true,
    includeIfNull: false,
  )


  final String orgId;



  @JsonKey(
    
    name: r'url',
    required: true,
    includeIfNull: false,
  )


  final String url;



  @JsonKey(
    
    name: r'title',
    required: false,
    includeIfNull: false,
  )


  final String? title;



  @JsonKey(
    
    name: r'text',
    required: true,
    includeIfNull: false,
  )


  final String text;



  @JsonKey(
    
    name: r'prefix',
    required: false,
    includeIfNull: false,
  )


  final String? prefix;



  @JsonKey(
    
    name: r'suffix',
    required: false,
    includeIfNull: false,
  )


  final String? suffix;



  @JsonKey(
    
    name: r'note',
    required: false,
    includeIfNull: false,
  )


  final String? note;





    @override
    bool operator ==(Object other) => identical(this, other) || other is CreateHighlightRequest &&
      other.orgId == orgId &&
      other.url == url &&
      other.title == title &&
      other.text == text &&
      other.prefix == prefix &&
      other.suffix == suffix &&
      other.note == note;

    @override
    int get hashCode =>
        orgId.hashCode +
        url.hashCode +
        title.hashCode +
        text.hashCode +
        prefix.hashCode +
        suffix.hashCode +
        note.hashCode;

  factory CreateHighlightRequest.fromJson(Map<String, dynamic> json) => _$CreateHighlightRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CreateHighlightRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

