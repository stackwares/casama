//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:kasama_api/src/model/device_event_input.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'report_device_events_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ReportDeviceEventsRequest {
  /// Returns a new [ReportDeviceEventsRequest] instance.
  ReportDeviceEventsRequest({

    required  this.events,
  });

  @JsonKey(
    
    name: r'events',
    required: true,
    includeIfNull: false,
  )


  final List<DeviceEventInput> events;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ReportDeviceEventsRequest &&
      other.events == events;

    @override
    int get hashCode =>
        events.hashCode;

  factory ReportDeviceEventsRequest.fromJson(Map<String, dynamic> json) => _$ReportDeviceEventsRequestFromJson(json);

  Map<String, dynamic> toJson() => _$ReportDeviceEventsRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

