//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'server_capacity_alerts_inner.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ServerCapacityAlertsInner {
  /// Returns a new [ServerCapacityAlertsInner] instance.
  ServerCapacityAlertsInner({

    required  this.kind,

    required  this.day,

    required  this.body,
  });

  @JsonKey(
    
    name: r'kind',
    required: true,
    includeIfNull: false,
  )


  final ServerCapacityAlertsInnerKindEnum kind;



  @JsonKey(
    
    name: r'day',
    required: true,
    includeIfNull: false,
  )


  final String day;



  @JsonKey(
    
    name: r'body',
    required: true,
    includeIfNull: false,
  )


  final String body;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ServerCapacityAlertsInner &&
      other.kind == kind &&
      other.day == day &&
      other.body == body;

    @override
    int get hashCode =>
        kind.hashCode +
        day.hashCode +
        body.hashCode;

  factory ServerCapacityAlertsInner.fromJson(Map<String, dynamic> json) => _$ServerCapacityAlertsInnerFromJson(json);

  Map<String, dynamic> toJson() => _$ServerCapacityAlertsInnerToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum ServerCapacityAlertsInnerKindEnum {
@JsonValue(r'early_warning')
earlyWarning(r'early_warning'),
@JsonValue(r'capacity_full')
capacityFull(r'capacity_full'),
@JsonValue(r'low_memory')
lowMemory(r'low_memory'),
@JsonValue(r'disk')
disk(r'disk');

const ServerCapacityAlertsInnerKindEnum(this.value);

final String value;

@override
String toString() => value;
}


