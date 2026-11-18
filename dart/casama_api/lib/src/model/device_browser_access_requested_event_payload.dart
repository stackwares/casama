//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'device_browser_access_requested_event_payload.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class DeviceBrowserAccessRequestedEventPayload {
  /// Returns a new [DeviceBrowserAccessRequestedEventPayload] instance.
  DeviceBrowserAccessRequestedEventPayload({

    required  this.kind,

    required  this.reason,

    required  this.botId,
  });

  @JsonKey(
    
    name: r'kind',
    required: true,
    includeIfNull: false,
  )


  final DeviceBrowserAccessRequestedEventPayloadKindEnum kind;



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
    bool operator ==(Object other) => identical(this, other) || other is DeviceBrowserAccessRequestedEventPayload &&
      other.kind == kind &&
      other.reason == reason &&
      other.botId == botId;

    @override
    int get hashCode =>
        kind.hashCode +
        reason.hashCode +
        botId.hashCode;

  factory DeviceBrowserAccessRequestedEventPayload.fromJson(Map<String, dynamic> json) => _$DeviceBrowserAccessRequestedEventPayloadFromJson(json);

  Map<String, dynamic> toJson() => _$DeviceBrowserAccessRequestedEventPayloadToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum DeviceBrowserAccessRequestedEventPayloadKindEnum {
@JsonValue(r'browser_tab')
browserTab(r'browser_tab'),
@JsonValue(r'browser_history')
browserHistory(r'browser_history');

const DeviceBrowserAccessRequestedEventPayloadKindEnum(this.value);

final String value;

@override
String toString() => value;
}


