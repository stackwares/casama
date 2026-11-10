//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'device_access_requested_event_payload.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class DeviceAccessRequestedEventPayload {
  /// Returns a new [DeviceAccessRequestedEventPayload] instance.
  DeviceAccessRequestedEventPayload({

    required  this.kind,

    required  this.reason,

    required  this.botId,
  });

  @JsonKey(
    
    name: r'kind',
    required: true,
    includeIfNull: false,
  )


  final DeviceAccessRequestedEventPayloadKindEnum kind;



  @JsonKey(
    
    name: r'reason',
    required: true,
    includeIfNull: false,
  )


  final String reason;



  @JsonKey(
    
    name: r'bot_id',
    required: true,
    includeIfNull: false,
  )


  final String botId;





    @override
    bool operator ==(Object other) => identical(this, other) || other is DeviceAccessRequestedEventPayload &&
      other.kind == kind &&
      other.reason == reason &&
      other.botId == botId;

    @override
    int get hashCode =>
        kind.hashCode +
        reason.hashCode +
        botId.hashCode;

  factory DeviceAccessRequestedEventPayload.fromJson(Map<String, dynamic> json) => _$DeviceAccessRequestedEventPayloadFromJson(json);

  Map<String, dynamic> toJson() => _$DeviceAccessRequestedEventPayloadToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum DeviceAccessRequestedEventPayloadKindEnum {
@JsonValue(r'calendar')
calendar(r'calendar'),
@JsonValue(r'reminders')
reminders(r'reminders'),
@JsonValue(r'contacts')
contacts(r'contacts'),
@JsonValue(r'places')
places(r'places'),
@JsonValue(r'photos')
photos(r'photos'),
@JsonValue(r'health')
health(r'health'),
@JsonValue(r'notifications')
notifications(r'notifications'),
@JsonValue(r'activity')
activity(r'activity');

const DeviceAccessRequestedEventPayloadKindEnum(this.value);

final String value;

@override
String toString() => value;
}


