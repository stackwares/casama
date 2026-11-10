//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:kasama_api/src/model/device_kind_settings.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'save_device_source_request_kinds.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SaveDeviceSourceRequestKinds {
  /// Returns a new [SaveDeviceSourceRequestKinds] instance.
  SaveDeviceSourceRequestKinds({

     this.calendar,

     this.reminders,

     this.contacts,

     this.places,

     this.photos,

     this.health,

     this.notifications,

     this.activity,
  });

  @JsonKey(
    
    name: r'calendar',
    required: false,
    includeIfNull: false,
  )


  final DeviceKindSettings? calendar;



  @JsonKey(
    
    name: r'reminders',
    required: false,
    includeIfNull: false,
  )


  final DeviceKindSettings? reminders;



  @JsonKey(
    
    name: r'contacts',
    required: false,
    includeIfNull: false,
  )


  final DeviceKindSettings? contacts;



  @JsonKey(
    
    name: r'places',
    required: false,
    includeIfNull: false,
  )


  final DeviceKindSettings? places;



  @JsonKey(
    
    name: r'photos',
    required: false,
    includeIfNull: false,
  )


  final DeviceKindSettings? photos;



  @JsonKey(
    
    name: r'health',
    required: false,
    includeIfNull: false,
  )


  final DeviceKindSettings? health;



  @JsonKey(
    
    name: r'notifications',
    required: false,
    includeIfNull: false,
  )


  final DeviceKindSettings? notifications;



  @JsonKey(
    
    name: r'activity',
    required: false,
    includeIfNull: false,
  )


  final DeviceKindSettings? activity;





    @override
    bool operator ==(Object other) => identical(this, other) || other is SaveDeviceSourceRequestKinds &&
      other.calendar == calendar &&
      other.reminders == reminders &&
      other.contacts == contacts &&
      other.places == places &&
      other.photos == photos &&
      other.health == health &&
      other.notifications == notifications &&
      other.activity == activity;

    @override
    int get hashCode =>
        calendar.hashCode +
        reminders.hashCode +
        contacts.hashCode +
        places.hashCode +
        photos.hashCode +
        health.hashCode +
        notifications.hashCode +
        activity.hashCode;

  factory SaveDeviceSourceRequestKinds.fromJson(Map<String, dynamic> json) => _$SaveDeviceSourceRequestKindsFromJson(json);

  Map<String, dynamic> toJson() => _$SaveDeviceSourceRequestKindsToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

