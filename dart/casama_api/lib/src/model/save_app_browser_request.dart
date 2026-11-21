//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/save_app_browser_request_reasons.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'save_app_browser_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SaveAppBrowserRequest {
  /// Returns a new [SaveAppBrowserRequest] instance.
  SaveAppBrowserRequest({

    required  this.stage,

     this.testers,

     this.reasons,

     this.systems,
  });

  @JsonKey(
    
    name: r'stage',
    required: true,
    includeIfNull: false,
  )


  final SaveAppBrowserRequestStageEnum stage;



  @JsonKey(
    
    name: r'testers',
    required: false,
    includeIfNull: false,
  )


  final List<String>? testers;



  @JsonKey(
    
    name: r'reasons',
    required: false,
    includeIfNull: false,
  )


  final SaveAppBrowserRequestReasons? reasons;



  @JsonKey(
    
    name: r'systems',
    required: false,
    includeIfNull: false,
  )


  final List<SaveAppBrowserRequestSystemsEnum>? systems;





    @override
    bool operator ==(Object other) => identical(this, other) || other is SaveAppBrowserRequest &&
      other.stage == stage &&
      other.testers == testers &&
      other.reasons == reasons &&
      other.systems == systems;

    @override
    int get hashCode =>
        stage.hashCode +
        testers.hashCode +
        reasons.hashCode +
        systems.hashCode;

  factory SaveAppBrowserRequest.fromJson(Map<String, dynamic> json) => _$SaveAppBrowserRequestFromJson(json);

  Map<String, dynamic> toJson() => _$SaveAppBrowserRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum SaveAppBrowserRequestStageEnum {
@JsonValue(r'off')
off(r'off'),
@JsonValue(r'testers')
testers(r'testers'),
@JsonValue(r'on')
on_(r'on');

const SaveAppBrowserRequestStageEnum(this.value);

final String value;

@override
String toString() => value;
}



enum SaveAppBrowserRequestSystemsEnum {
@JsonValue(r'ios')
ios(r'ios'),
@JsonValue(r'android')
android(r'android');

const SaveAppBrowserRequestSystemsEnum(this.value);

final String value;

@override
String toString() => value;
}


