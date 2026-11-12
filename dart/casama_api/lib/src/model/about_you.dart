//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'about_you.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AboutYou {
  /// Returns a new [AboutYou] instance.
  AboutYou({

    required  this.displayName,

    required  this.preferredName,

    required  this.pronouns,

    required  this.about,

    required  this.replyStyle,

    required  this.learn,

    required  this.nameAsked,

     this.photoId,

     this.providerPhoto,

     this.photoImportTried,
  });

  @JsonKey(
    
    name: r'display_name',
    required: true,
    includeIfNull: true,
  )


  final String? displayName;



  @JsonKey(
    
    name: r'preferred_name',
    required: true,
    includeIfNull: true,
  )


  final String? preferredName;



  @JsonKey(
    
    name: r'pronouns',
    required: true,
    includeIfNull: true,
  )


  final String? pronouns;



  @JsonKey(
    
    name: r'about',
    required: true,
    includeIfNull: false,
  )


  final String about;



  @JsonKey(
    
    name: r'reply_style',
    required: true,
    includeIfNull: false,
  )


  final String replyStyle;



  @JsonKey(
    
    name: r'learn',
    required: true,
    includeIfNull: false,
  )


  final bool learn;



  @JsonKey(
    
    name: r'name_asked',
    required: true,
    includeIfNull: false,
  )


  final bool nameAsked;



  @JsonKey(
    
    name: r'photo_id',
    required: false,
    includeIfNull: false,
  )


  final String? photoId;



  @JsonKey(
    
    name: r'provider_photo',
    required: false,
    includeIfNull: false,
  )


  final bool? providerPhoto;



  @JsonKey(
    
    name: r'photo_import_tried',
    required: false,
    includeIfNull: false,
  )


  final bool? photoImportTried;





    @override
    bool operator ==(Object other) => identical(this, other) || other is AboutYou &&
      other.displayName == displayName &&
      other.preferredName == preferredName &&
      other.pronouns == pronouns &&
      other.about == about &&
      other.replyStyle == replyStyle &&
      other.learn == learn &&
      other.nameAsked == nameAsked &&
      other.photoId == photoId &&
      other.providerPhoto == providerPhoto &&
      other.photoImportTried == photoImportTried;

    @override
    int get hashCode =>
        (displayName == null ? 0 : displayName.hashCode) +
        (preferredName == null ? 0 : preferredName.hashCode) +
        (pronouns == null ? 0 : pronouns.hashCode) +
        about.hashCode +
        replyStyle.hashCode +
        learn.hashCode +
        nameAsked.hashCode +
        (photoId == null ? 0 : photoId.hashCode) +
        providerPhoto.hashCode +
        photoImportTried.hashCode;

  factory AboutYou.fromJson(Map<String, dynamic> json) => _$AboutYouFromJson(json);

  Map<String, dynamic> toJson() => _$AboutYouToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

