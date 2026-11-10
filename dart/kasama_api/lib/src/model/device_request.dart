//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'device_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class DeviceRequest {
  /// Returns a new [DeviceRequest] instance.
  DeviceRequest({

    required  this.id,

    required  this.sourceId,

    required  this.kind,

    required  this.action,

    required  this.params,

    required  this.createdAt,
  });

  @JsonKey(
    
    name: r'id',
    required: true,
    includeIfNull: false,
  )


  final String id;



  @JsonKey(
    
    name: r'source_id',
    required: true,
    includeIfNull: false,
  )


  final String sourceId;



  @JsonKey(
    
    name: r'kind',
    required: true,
    includeIfNull: false,
  )


  final String kind;



  @JsonKey(
    
    name: r'action',
    required: true,
    includeIfNull: false,
  )


  final DeviceRequestActionEnum action;



  @JsonKey(
    
    name: r'params',
    required: true,
    includeIfNull: false,
  )


  final Map<String, Object?> params;



  @JsonKey(
    
    name: r'created_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime createdAt;





    @override
    bool operator ==(Object other) => identical(this, other) || other is DeviceRequest &&
      other.id == id &&
      other.sourceId == sourceId &&
      other.kind == kind &&
      other.action == action &&
      other.params == params &&
      other.createdAt == createdAt;

    @override
    int get hashCode =>
        id.hashCode +
        sourceId.hashCode +
        kind.hashCode +
        action.hashCode +
        params.hashCode +
        createdAt.hashCode;

  factory DeviceRequest.fromJson(Map<String, dynamic> json) => _$DeviceRequestFromJson(json);

  Map<String, dynamic> toJson() => _$DeviceRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum DeviceRequestActionEnum {
@JsonValue(r'read')
read(r'read'),
@JsonValue(r'calendar.create')
calendarPeriodCreate(r'calendar.create'),
@JsonValue(r'reminders.create')
remindersPeriodCreate(r'reminders.create');

const DeviceRequestActionEnum(this.value);

final String value;

@override
String toString() => value;
}


