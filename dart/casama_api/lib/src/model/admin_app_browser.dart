//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/app_browser_numbers.dart';
import 'package:casama_api/src/model/app_browser_settings.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'admin_app_browser.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminAppBrowser {
  /// Returns a new [AdminAppBrowser] instance.
  AdminAppBrowser({

    required  this.settings,

    required  this.numbers,
  });

  @JsonKey(
    
    name: r'settings',
    required: true,
    includeIfNull: false,
  )


  final AppBrowserSettings settings;



  @JsonKey(
    
    name: r'numbers',
    required: true,
    includeIfNull: false,
  )


  final AppBrowserNumbers numbers;





    @override
    bool operator ==(Object other) => identical(this, other) || other is AdminAppBrowser &&
      other.settings == settings &&
      other.numbers == numbers;

    @override
    int get hashCode =>
        settings.hashCode +
        numbers.hashCode;

  factory AdminAppBrowser.fromJson(Map<String, dynamic> json) => _$AdminAppBrowserFromJson(json);

  Map<String, dynamic> toJson() => _$AdminAppBrowserToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

