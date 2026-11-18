//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'calendar_trigger_config.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CalendarTriggerConfig {
  /// Returns a new [CalendarTriggerConfig] instance.
  CalendarTriggerConfig({

    required  this.integrationId,

    required  this.offsetMinutes,

     this.anchor,

     this.calendar,

     this.outsideGuests,

     this.titleMatch,

     this.hasVideoLink,
  });

      /// A connected Google or Outlook calendar
  @JsonKey(
    
    name: r'integration_id',
    required: true,
    includeIfNull: false,
  )


  final String integrationId;



      /// Relative to the event's start (or end, with anchor end); -15 is 15 minutes before
          // minimum: -1440
          // maximum: 1440
  @JsonKey(
    
    name: r'offset_minutes',
    required: true,
    includeIfNull: false,
  )


  final int offsetMinutes;



      /// What the offset counts from; end is for after a meeting (D-287)
  @JsonKey(
    
    name: r'anchor',
    required: false,
    includeIfNull: false,
  )


  final CalendarTriggerConfigAnchorEnum? anchor;



  @JsonKey(
    
    name: r'calendar',
    required: false,
    includeIfNull: false,
  )


  final String? calendar;



  @JsonKey(
    
    name: r'outside_guests',
    required: false,
    includeIfNull: false,
  )


  final bool? outsideGuests;



  @JsonKey(
    
    name: r'title_match',
    required: false,
    includeIfNull: false,
  )


  final String? titleMatch;



  @JsonKey(
    
    name: r'has_video_link',
    required: false,
    includeIfNull: false,
  )


  final bool? hasVideoLink;





    @override
    bool operator ==(Object other) => identical(this, other) || other is CalendarTriggerConfig &&
      other.integrationId == integrationId &&
      other.offsetMinutes == offsetMinutes &&
      other.anchor == anchor &&
      other.calendar == calendar &&
      other.outsideGuests == outsideGuests &&
      other.titleMatch == titleMatch &&
      other.hasVideoLink == hasVideoLink;

    @override
    int get hashCode =>
        integrationId.hashCode +
        offsetMinutes.hashCode +
        anchor.hashCode +
        calendar.hashCode +
        outsideGuests.hashCode +
        titleMatch.hashCode +
        hasVideoLink.hashCode;

  factory CalendarTriggerConfig.fromJson(Map<String, dynamic> json) => _$CalendarTriggerConfigFromJson(json);

  Map<String, dynamic> toJson() => _$CalendarTriggerConfigToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

/// What the offset counts from; end is for after a meeting (D-287)
enum CalendarTriggerConfigAnchorEnum {
    /// What the offset counts from; end is for after a meeting (D-287)
@JsonValue(r'start')
start(r'start'),
    /// What the offset counts from; end is for after a meeting (D-287)
@JsonValue(r'end')
end(r'end');

const CalendarTriggerConfigAnchorEnum(this.value);

final String value;

@override
String toString() => value;
}


