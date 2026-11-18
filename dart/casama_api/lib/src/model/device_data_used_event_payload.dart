//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'device_data_used_event_payload.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class DeviceDataUsedEventPayload {
  /// Returns a new [DeviceDataUsedEventPayload] instance.
  DeviceDataUsedEventPayload({

    required  this.kind,

    required  this.count,

    required  this.from,

    required  this.to,

    required  this.devices,
  });

  @JsonKey(
    
    name: r'kind',
    required: true,
    includeIfNull: false,
  )


  final String kind;



  @JsonKey(
    
    name: r'count',
    required: true,
    includeIfNull: false,
  )


  final int count;



  @JsonKey(
    
    name: r'from',
    required: true,
    includeIfNull: false,
  )


  final String from;



  @JsonKey(
    
    name: r'to',
    required: true,
    includeIfNull: false,
  )


  final String to;



  @JsonKey(
    
    name: r'devices',
    required: true,
    includeIfNull: false,
  )


  final List<String> devices;





    @override
    bool operator ==(Object other) => identical(this, other) || other is DeviceDataUsedEventPayload &&
      other.kind == kind &&
      other.count == count &&
      other.from == from &&
      other.to == to &&
      other.devices == devices;

    @override
    int get hashCode =>
        kind.hashCode +
        count.hashCode +
        from.hashCode +
        to.hashCode +
        devices.hashCode;

  factory DeviceDataUsedEventPayload.fromJson(Map<String, dynamic> json) => _$DeviceDataUsedEventPayloadFromJson(json);

  Map<String, dynamic> toJson() => _$DeviceDataUsedEventPayloadToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

