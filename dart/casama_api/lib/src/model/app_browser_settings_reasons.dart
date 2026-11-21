//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'app_browser_settings_reasons.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AppBrowserSettingsReasons {
  /// Returns a new [AppBrowserSettingsReasons] instance.
  AppBrowserSettingsReasons({

    required  this.asked,

    required  this.blocked,

    required  this.signedIn,
  });

      /// The person asks for it
  @JsonKey(
    
    name: r'asked',
    required: true,
    includeIfNull: false,
  )


  final bool asked;



      /// The site blocks the bot's computer
  @JsonKey(
    
    name: r'blocked',
    required: true,
    includeIfNull: false,
  )


  final bool blocked;



      /// The person signed in to the site on the phone
  @JsonKey(
    
    name: r'signed_in',
    required: true,
    includeIfNull: false,
  )


  final bool signedIn;





    @override
    bool operator ==(Object other) => identical(this, other) || other is AppBrowserSettingsReasons &&
      other.asked == asked &&
      other.blocked == blocked &&
      other.signedIn == signedIn;

    @override
    int get hashCode =>
        asked.hashCode +
        blocked.hashCode +
        signedIn.hashCode;

  factory AppBrowserSettingsReasons.fromJson(Map<String, dynamic> json) => _$AppBrowserSettingsReasonsFromJson(json);

  Map<String, dynamic> toJson() => _$AppBrowserSettingsReasonsToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

