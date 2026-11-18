//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'relayed_analytics_event.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class RelayedAnalyticsEvent {
  /// Returns a new [RelayedAnalyticsEvent] instance.
  RelayedAnalyticsEvent({

    required  this.name,

     this.properties,
  });

      /// A catalog event the app may send, or screen_view
  @JsonKey(
    
    name: r'name',
    required: true,
    includeIfNull: false,
  )


  final String name;



      /// Catalog properties: strings, numbers or booleans; anything else is dropped
  @JsonKey(
    
    name: r'properties',
    required: false,
    includeIfNull: false,
  )


  final Map<String, Object?>? properties;





    @override
    bool operator ==(Object other) => identical(this, other) || other is RelayedAnalyticsEvent &&
      other.name == name &&
      other.properties == properties;

    @override
    int get hashCode =>
        name.hashCode +
        properties.hashCode;

  factory RelayedAnalyticsEvent.fromJson(Map<String, dynamic> json) => _$RelayedAnalyticsEventFromJson(json);

  Map<String, dynamic> toJson() => _$RelayedAnalyticsEventToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

