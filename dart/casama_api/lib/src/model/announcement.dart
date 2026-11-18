//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'announcement.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Announcement {
  /// Returns a new [Announcement] instance.
  Announcement({

    required  this.id,

    required  this.title,

    required  this.body,

     this.url,

    required  this.level,

     this.startsAt,

     this.endsAt,

     this.platforms,

     this.minVersion,

     this.maxVersion,
  });

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



  @JsonKey(
    
    name: r'body',
    required: true,
    includeIfNull: false,
  )


  final String body;



  @JsonKey(
    
    name: r'url',
    required: false,
    includeIfNull: false,
  )


  final String? url;



  @JsonKey(
    
    name: r'level',
    required: true,
    includeIfNull: false,
  )


  final AnnouncementLevelEnum level;



  @JsonKey(
    
    name: r'starts_at',
    required: false,
    includeIfNull: false,
  )


  final String? startsAt;



  @JsonKey(
    
    name: r'ends_at',
    required: false,
    includeIfNull: false,
  )


  final String? endsAt;



  @JsonKey(
    
    name: r'platforms',
    required: false,
    includeIfNull: false,
  )


  final List<AnnouncementPlatformsEnum>? platforms;



  @JsonKey(
    
    name: r'min_version',
    required: false,
    includeIfNull: false,
  )


  final String? minVersion;



  @JsonKey(
    
    name: r'max_version',
    required: false,
    includeIfNull: false,
  )


  final String? maxVersion;





    @override
    bool operator ==(Object other) => identical(this, other) || other is Announcement &&
      other.id == id &&
      other.title == title &&
      other.body == body &&
      other.url == url &&
      other.level == level &&
      other.startsAt == startsAt &&
      other.endsAt == endsAt &&
      other.platforms == platforms &&
      other.minVersion == minVersion &&
      other.maxVersion == maxVersion;

    @override
    int get hashCode =>
        id.hashCode +
        title.hashCode +
        body.hashCode +
        url.hashCode +
        level.hashCode +
        startsAt.hashCode +
        endsAt.hashCode +
        platforms.hashCode +
        minVersion.hashCode +
        maxVersion.hashCode;

  factory Announcement.fromJson(Map<String, dynamic> json) => _$AnnouncementFromJson(json);

  Map<String, dynamic> toJson() => _$AnnouncementToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum AnnouncementLevelEnum {
@JsonValue(r'info')
info(r'info'),
@JsonValue(r'warning')
warning(r'warning');

const AnnouncementLevelEnum(this.value);

final String value;

@override
String toString() => value;
}



enum AnnouncementPlatformsEnum {
@JsonValue(r'ios')
ios(r'ios'),
@JsonValue(r'android')
android(r'android'),
@JsonValue(r'macos')
macos(r'macos'),
@JsonValue(r'windows')
windows(r'windows'),
@JsonValue(r'linux')
linux(r'linux'),
@JsonValue(r'web')
web(r'web');

const AnnouncementPlatformsEnum(this.value);

final String value;

@override
String toString() => value;
}


