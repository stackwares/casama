//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'update_plugin_settings_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class UpdatePluginSettingsRequest {
  /// Returns a new [UpdatePluginSettingsRequest] instance.
  UpdatePluginSettingsRequest({

    required  this.settings,
  });

  @JsonKey(
    
    name: r'settings',
    required: true,
    includeIfNull: false,
  )


  final Map<String, String> settings;





    @override
    bool operator ==(Object other) => identical(this, other) || other is UpdatePluginSettingsRequest &&
      other.settings == settings;

    @override
    int get hashCode =>
        settings.hashCode;

  factory UpdatePluginSettingsRequest.fromJson(Map<String, dynamic> json) => _$UpdatePluginSettingsRequestFromJson(json);

  Map<String, dynamic> toJson() => _$UpdatePluginSettingsRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

