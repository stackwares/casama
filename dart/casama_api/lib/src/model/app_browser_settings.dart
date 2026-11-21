//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/app_browser_settings_reasons.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'app_browser_settings.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AppBrowserSettings {
  /// Returns a new [AppBrowserSettings] instance.
  AppBrowserSettings({

    required  this.stage,

    required  this.testers,

    required  this.reasons,

    required  this.systems,
  });

      /// \"off\": nobody; \"testers\": the people listed; \"on\": everyone on a listed system
  @JsonKey(
    
    name: r'stage',
    required: true,
    includeIfNull: false,
  )


  final AppBrowserSettingsStageEnum stage;



  @JsonKey(
    
    name: r'testers',
    required: true,
    includeIfNull: false,
  )


  final List<String> testers;



  @JsonKey(
    
    name: r'reasons',
    required: true,
    includeIfNull: false,
  )


  final AppBrowserSettingsReasons reasons;



      /// \"ios\", \"android\"
  @JsonKey(
    
    name: r'systems',
    required: true,
    includeIfNull: false,
  )


  final List<String> systems;





    @override
    bool operator ==(Object other) => identical(this, other) || other is AppBrowserSettings &&
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

  factory AppBrowserSettings.fromJson(Map<String, dynamic> json) => _$AppBrowserSettingsFromJson(json);

  Map<String, dynamic> toJson() => _$AppBrowserSettingsToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

/// \"off\": nobody; \"testers\": the people listed; \"on\": everyone on a listed system
enum AppBrowserSettingsStageEnum {
    /// \"off\": nobody; \"testers\": the people listed; \"on\": everyone on a listed system
@JsonValue(r'off')
off(r'off'),
    /// \"off\": nobody; \"testers\": the people listed; \"on\": everyone on a listed system
@JsonValue(r'testers')
testers(r'testers'),
    /// \"off\": nobody; \"testers\": the people listed; \"on\": everyone on a listed system
@JsonValue(r'on')
on_(r'on');

const AppBrowserSettingsStageEnum(this.value);

final String value;

@override
String toString() => value;
}


