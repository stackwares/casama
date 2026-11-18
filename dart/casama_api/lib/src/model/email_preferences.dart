//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'email_preferences.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class EmailPreferences {
  /// Returns a new [EmailPreferences] instance.
  EmailPreferences({

    required  this.tips,

     this.galleryDigest,
  });

  @JsonKey(
    
    name: r'tips',
    required: true,
    includeIfNull: false,
  )


  final bool tips;



      /// Monthly gallery picks by email (opt-in, D-315)
  @JsonKey(
    
    name: r'gallery_digest',
    required: false,
    includeIfNull: false,
  )


  final bool? galleryDigest;





    @override
    bool operator ==(Object other) => identical(this, other) || other is EmailPreferences &&
      other.tips == tips &&
      other.galleryDigest == galleryDigest;

    @override
    int get hashCode =>
        tips.hashCode +
        galleryDigest.hashCode;

  factory EmailPreferences.fromJson(Map<String, dynamic> json) => _$EmailPreferencesFromJson(json);

  Map<String, dynamic> toJson() => _$EmailPreferencesToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

