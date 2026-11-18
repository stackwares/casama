//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'set_remote_access_settings_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SetRemoteAccessSettingsRequest {
  /// Returns a new [SetRemoteAccessSettingsRequest] instance.
  SetRemoteAccessSettingsRequest({

    required  this.privateNotifications,
  });

  @JsonKey(
    
    name: r'private_notifications',
    required: true,
    includeIfNull: false,
  )


  final bool privateNotifications;





    @override
    bool operator ==(Object other) => identical(this, other) || other is SetRemoteAccessSettingsRequest &&
      other.privateNotifications == privateNotifications;

    @override
    int get hashCode =>
        privateNotifications.hashCode;

  factory SetRemoteAccessSettingsRequest.fromJson(Map<String, dynamic> json) => _$SetRemoteAccessSettingsRequestFromJson(json);

  Map<String, dynamic> toJson() => _$SetRemoteAccessSettingsRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

