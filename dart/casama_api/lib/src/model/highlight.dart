//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'highlight.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Highlight {
  /// Returns a new [Highlight] instance.
  Highlight({

    required  this.id,

    required  this.orgId,

    required  this.url,

    required  this.urlKey,

    required  this.title,

    required  this.text,

    required  this.prefix,

    required  this.suffix,

    required  this.note,

    required  this.createdAt,
  });

  @JsonKey(
    
    name: r'id',
    required: true,
    includeIfNull: false,
  )


  final String id;



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
    
    name: r'url_key',
    required: true,
    includeIfNull: false,
  )


  final String urlKey;



  @JsonKey(
    
    name: r'title',
    required: true,
    includeIfNull: false,
  )


  final String title;



  @JsonKey(
    
    name: r'text',
    required: true,
    includeIfNull: false,
  )


  final String text;



  @JsonKey(
    
    name: r'prefix',
    required: true,
    includeIfNull: false,
  )


  final String prefix;



  @JsonKey(
    
    name: r'suffix',
    required: true,
    includeIfNull: false,
  )


  final String suffix;



  @JsonKey(
    
    name: r'note',
    required: true,
    includeIfNull: false,
  )


  final String note;



  @JsonKey(
    
    name: r'created_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime createdAt;





    @override
    bool operator ==(Object other) => identical(this, other) || other is Highlight &&
      other.id == id &&
      other.orgId == orgId &&
      other.url == url &&
      other.urlKey == urlKey &&
      other.title == title &&
      other.text == text &&
      other.prefix == prefix &&
      other.suffix == suffix &&
      other.note == note &&
      other.createdAt == createdAt;

    @override
    int get hashCode =>
        id.hashCode +
        orgId.hashCode +
        url.hashCode +
        urlKey.hashCode +
        title.hashCode +
        text.hashCode +
        prefix.hashCode +
        suffix.hashCode +
        note.hashCode +
        createdAt.hashCode;

  factory Highlight.fromJson(Map<String, dynamic> json) => _$HighlightFromJson(json);

  Map<String, dynamic> toJson() => _$HighlightToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

