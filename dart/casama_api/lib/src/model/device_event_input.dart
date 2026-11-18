//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'device_event_input.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class DeviceEventInput {
  /// Returns a new [DeviceEventInput] instance.
  DeviceEventInput({

    required  this.id,

    required  this.type,

    required  this.at,

     this.place,

     this.app,

     this.title,

     this.text,

     this.folder,

     this.name,

     this.site,
  });

      /// Unique per event on the device, so a retry never fires twice
  @JsonKey(
    
    name: r'id',
    required: true,
    includeIfNull: false,
  )


  final String id;



  @JsonKey(
    
    name: r'type',
    required: true,
    includeIfNull: false,
  )


  final DeviceEventInputTypeEnum type;



  @JsonKey(
    
    name: r'at',
    required: true,
    includeIfNull: false,
  )


  final DateTime at;



  @JsonKey(
    
    name: r'place',
    required: false,
    includeIfNull: false,
  )


  final String? place;



  @JsonKey(
    
    name: r'app',
    required: false,
    includeIfNull: false,
  )


  final String? app;



  @JsonKey(
    
    name: r'title',
    required: false,
    includeIfNull: false,
  )


  final String? title;



  @JsonKey(
    
    name: r'text',
    required: false,
    includeIfNull: false,
  )


  final String? text;



      /// file_added: the watched folder's name (Downloads)
  @JsonKey(
    
    name: r'folder',
    required: false,
    includeIfNull: false,
  )


  final String? folder;



      /// file_added and download_done: the new file's name
  @JsonKey(
    
    name: r'name',
    required: false,
    includeIfNull: false,
  )


  final String? name;



      /// site_opened, download_done and bookmark_added (Casama for Chrome): the site's host only, no path
  @JsonKey(
    
    name: r'site',
    required: false,
    includeIfNull: false,
  )


  final String? site;





    @override
    bool operator ==(Object other) => identical(this, other) || other is DeviceEventInput &&
      other.id == id &&
      other.type == type &&
      other.at == at &&
      other.place == place &&
      other.app == app &&
      other.title == title &&
      other.text == text &&
      other.folder == folder &&
      other.name == name &&
      other.site == site;

    @override
    int get hashCode =>
        id.hashCode +
        type.hashCode +
        at.hashCode +
        place.hashCode +
        app.hashCode +
        title.hashCode +
        text.hashCode +
        folder.hashCode +
        name.hashCode +
        site.hashCode;

  factory DeviceEventInput.fromJson(Map<String, dynamic> json) => _$DeviceEventInputFromJson(json);

  Map<String, dynamic> toJson() => _$DeviceEventInputToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum DeviceEventInputTypeEnum {
@JsonValue(r'wake')
wake(r'wake'),
@JsonValue(r'arrive')
arrive(r'arrive'),
@JsonValue(r'leave')
leave(r'leave'),
@JsonValue(r'workout_ended')
workoutEnded(r'workout_ended'),
@JsonValue(r'notification')
notification(r'notification'),
@JsonValue(r'focus_on')
focusOn(r'focus_on'),
@JsonValue(r'focus_off')
focusOff(r'focus_off'),
@JsonValue(r'file_added')
fileAdded(r'file_added'),
@JsonValue(r'driving_on')
drivingOn(r'driving_on'),
@JsonValue(r'driving_off')
drivingOff(r'driving_off'),
@JsonValue(r'site_opened')
siteOpened(r'site_opened'),
@JsonValue(r'download_done')
downloadDone(r'download_done'),
@JsonValue(r'bookmark_added')
bookmarkAdded(r'bookmark_added');

const DeviceEventInputTypeEnum(this.value);

final String value;

@override
String toString() => value;
}


