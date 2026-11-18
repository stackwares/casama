//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'ask_device_permission_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AskDevicePermissionRequest {
  /// Returns a new [AskDevicePermissionRequest] instance.
  AskDevicePermissionRequest({

    required  this.permission,

    required  this.do_,

     this.botId,
  });

      /// location, location_always, camera, microphone, speech, photos, contacts, calendar, health, notifications, notification_access, accessibility, screen_recording, automation, full_disk, shared_folders, local_tools; more may come
  @JsonKey(
    
    name: r'permission',
    required: true,
    includeIfNull: false,
  )


  final String permission;



      /// request: show the system prompt, or open settings if the system won't ask again; open_settings: open the page with the switch; relaunch: restart Casama on that device
  @JsonKey(
    
    name: r'do',
    required: true,
    includeIfNull: false,
  )


  final AskDevicePermissionRequestDo_Enum do_;



      /// The bot whose card this came from
  @JsonKey(
    
    name: r'bot_id',
    required: false,
    includeIfNull: false,
  )


  final String? botId;





    @override
    bool operator ==(Object other) => identical(this, other) || other is AskDevicePermissionRequest &&
      other.permission == permission &&
      other.do_ == do_ &&
      other.botId == botId;

    @override
    int get hashCode =>
        permission.hashCode +
        do_.hashCode +
        botId.hashCode;

  factory AskDevicePermissionRequest.fromJson(Map<String, dynamic> json) => _$AskDevicePermissionRequestFromJson(json);

  Map<String, dynamic> toJson() => _$AskDevicePermissionRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

/// request: show the system prompt, or open settings if the system won't ask again; open_settings: open the page with the switch; relaunch: restart Casama on that device
enum AskDevicePermissionRequestDo_Enum {
    /// request: show the system prompt, or open settings if the system won't ask again; open_settings: open the page with the switch; relaunch: restart Casama on that device
@JsonValue(r'request')
request(r'request'),
    /// request: show the system prompt, or open settings if the system won't ask again; open_settings: open the page with the switch; relaunch: restart Casama on that device
@JsonValue(r'open_settings')
openSettings(r'open_settings'),
    /// request: show the system prompt, or open settings if the system won't ask again; open_settings: open the page with the switch; relaunch: restart Casama on that device
@JsonValue(r'relaunch')
relaunch(r'relaunch');

const AskDevicePermissionRequestDo_Enum(this.value);

final String value;

@override
String toString() => value;
}


