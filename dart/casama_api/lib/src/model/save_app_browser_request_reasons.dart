//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'save_app_browser_request_reasons.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SaveAppBrowserRequestReasons {
  /// Returns a new [SaveAppBrowserRequestReasons] instance.
  SaveAppBrowserRequestReasons({

     this.asked,

     this.blocked,

     this.signedIn,
  });

  @JsonKey(
    
    name: r'asked',
    required: false,
    includeIfNull: false,
  )


  final bool? asked;



  @JsonKey(
    
    name: r'blocked',
    required: false,
    includeIfNull: false,
  )


  final bool? blocked;



  @JsonKey(
    
    name: r'signed_in',
    required: false,
    includeIfNull: false,
  )


  final bool? signedIn;





    @override
    bool operator ==(Object other) => identical(this, other) || other is SaveAppBrowserRequestReasons &&
      other.asked == asked &&
      other.blocked == blocked &&
      other.signedIn == signedIn;

    @override
    int get hashCode =>
        asked.hashCode +
        blocked.hashCode +
        signedIn.hashCode;

  factory SaveAppBrowserRequestReasons.fromJson(Map<String, dynamic> json) => _$SaveAppBrowserRequestReasonsFromJson(json);

  Map<String, dynamic> toJson() => _$SaveAppBrowserRequestReasonsToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

