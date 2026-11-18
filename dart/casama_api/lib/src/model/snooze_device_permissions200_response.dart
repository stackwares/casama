//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'snooze_device_permissions200_response.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SnoozeDevicePermissions200Response {
  /// Returns a new [SnoozeDevicePermissions200Response] instance.
  SnoozeDevicePermissions200Response({

    required  this.until,
  });

  @JsonKey(
    
    name: r'until',
    required: true,
    includeIfNull: false,
  )


  final DateTime until;





    @override
    bool operator ==(Object other) => identical(this, other) || other is SnoozeDevicePermissions200Response &&
      other.until == until;

    @override
    int get hashCode =>
        until.hashCode;

  factory SnoozeDevicePermissions200Response.fromJson(Map<String, dynamic> json) => _$SnoozeDevicePermissions200ResponseFromJson(json);

  Map<String, dynamic> toJson() => _$SnoozeDevicePermissions200ResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

