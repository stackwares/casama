//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'update_about_you_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class UpdateAboutYouRequest {
  /// Returns a new [UpdateAboutYouRequest] instance.
  UpdateAboutYouRequest({

     this.preferredName,

     this.pronouns,

     this.about,

     this.replyStyle,

     this.learn,

     this.nameAsked,
  });

  @JsonKey(
    
    name: r'preferred_name',
    required: false,
    includeIfNull: false,
  )


  final String? preferredName;



  @JsonKey(
    
    name: r'pronouns',
    required: false,
    includeIfNull: false,
  )


  final String? pronouns;



  @JsonKey(
    
    name: r'about',
    required: false,
    includeIfNull: false,
  )


  final String? about;



  @JsonKey(
    
    name: r'reply_style',
    required: false,
    includeIfNull: false,
  )


  final String? replyStyle;



  @JsonKey(
    
    name: r'learn',
    required: false,
    includeIfNull: false,
  )


  final bool? learn;



  @JsonKey(
    
    name: r'name_asked',
    required: false,
    includeIfNull: false,
  )


  final bool? nameAsked;





    @override
    bool operator ==(Object other) => identical(this, other) || other is UpdateAboutYouRequest &&
      other.preferredName == preferredName &&
      other.pronouns == pronouns &&
      other.about == about &&
      other.replyStyle == replyStyle &&
      other.learn == learn &&
      other.nameAsked == nameAsked;

    @override
    int get hashCode =>
        (preferredName == null ? 0 : preferredName.hashCode) +
        (pronouns == null ? 0 : pronouns.hashCode) +
        about.hashCode +
        replyStyle.hashCode +
        learn.hashCode +
        nameAsked.hashCode;

  factory UpdateAboutYouRequest.fromJson(Map<String, dynamic> json) => _$UpdateAboutYouRequestFromJson(json);

  Map<String, dynamic> toJson() => _$UpdateAboutYouRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

