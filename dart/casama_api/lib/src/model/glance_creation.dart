//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'glance_creation.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class GlanceCreation {
  /// Returns a new [GlanceCreation] instance.
  GlanceCreation({

    required  this.id,

    required  this.kind,

    required  this.title,

    required  this.bot,

    required  this.hasCover,

    required  this.version,

    required  this.at,

    required  this.link,
  });

  @JsonKey(
    
    name: r'id',
    required: true,
    includeIfNull: false,
  )


  final String id;



  @JsonKey(
    
    name: r'kind',
    required: true,
    includeIfNull: false,
  )


  final GlanceCreationKindEnum kind;



  @JsonKey(
    
    name: r'title',
    required: true,
    includeIfNull: false,
  )


  final String title;



  @JsonKey(
    
    name: r'bot',
    required: true,
    includeIfNull: true,
  )


  final String? bot;



  @JsonKey(
    
    name: r'has_cover',
    required: true,
    includeIfNull: false,
  )


  final bool hasCover;



  @JsonKey(
    
    name: r'version',
    required: true,
    includeIfNull: false,
  )


  final int version;



  @JsonKey(
    
    name: r'at',
    required: true,
    includeIfNull: false,
  )


  final DateTime at;



  @JsonKey(
    
    name: r'link',
    required: true,
    includeIfNull: false,
  )


  final String link;





    @override
    bool operator ==(Object other) => identical(this, other) || other is GlanceCreation &&
      other.id == id &&
      other.kind == kind &&
      other.title == title &&
      other.bot == bot &&
      other.hasCover == hasCover &&
      other.version == version &&
      other.at == at &&
      other.link == link;

    @override
    int get hashCode =>
        id.hashCode +
        kind.hashCode +
        title.hashCode +
        (bot == null ? 0 : bot.hashCode) +
        hasCover.hashCode +
        version.hashCode +
        at.hashCode +
        link.hashCode;

  factory GlanceCreation.fromJson(Map<String, dynamic> json) => _$GlanceCreationFromJson(json);

  Map<String, dynamic> toJson() => _$GlanceCreationToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum GlanceCreationKindEnum {
@JsonValue(r'page')
page(r'page'),
@JsonValue(r'image')
image(r'image'),
@JsonValue(r'video')
video(r'video'),
@JsonValue(r'audio')
audio(r'audio'),
@JsonValue(r'document')
document(r'document'),
@JsonValue(r'file')
file(r'file');

const GlanceCreationKindEnum(this.value);

final String value;

@override
String toString() => value;
}


