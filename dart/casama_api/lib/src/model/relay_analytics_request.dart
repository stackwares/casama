//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/relayed_analytics_event.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'relay_analytics_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class RelayAnalyticsRequest {
  /// Returns a new [RelayAnalyticsRequest] instance.
  RelayAnalyticsRequest({

    required  this.platform,

    required  this.events,
  });

  @JsonKey(
    
    name: r'platform',
    required: true,
    includeIfNull: false,
  )


  final RelayAnalyticsRequestPlatformEnum platform;



  @JsonKey(
    
    name: r'events',
    required: true,
    includeIfNull: false,
  )


  final List<RelayedAnalyticsEvent> events;





    @override
    bool operator ==(Object other) => identical(this, other) || other is RelayAnalyticsRequest &&
      other.platform == platform &&
      other.events == events;

    @override
    int get hashCode =>
        platform.hashCode +
        events.hashCode;

  factory RelayAnalyticsRequest.fromJson(Map<String, dynamic> json) => _$RelayAnalyticsRequestFromJson(json);

  Map<String, dynamic> toJson() => _$RelayAnalyticsRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum RelayAnalyticsRequestPlatformEnum {
@JsonValue(r'windows')
windows(r'windows'),
@JsonValue(r'linux')
linux(r'linux');

const RelayAnalyticsRequestPlatformEnum(this.value);

final String value;

@override
String toString() => value;
}


