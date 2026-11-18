//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'ask_device_permission_result.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AskDevicePermissionResult {
  /// Returns a new [AskDevicePermissionResult] instance.
  AskDevicePermissionResult({

    required  this.via,
  });

      /// socket: the computer got it at once; notification: the phone gets a notification to tap (phones can't show a prompt from the background)
  @JsonKey(
    
    name: r'via',
    required: true,
    includeIfNull: false,
  )


  final AskDevicePermissionResultViaEnum via;





    @override
    bool operator ==(Object other) => identical(this, other) || other is AskDevicePermissionResult &&
      other.via == via;

    @override
    int get hashCode =>
        via.hashCode;

  factory AskDevicePermissionResult.fromJson(Map<String, dynamic> json) => _$AskDevicePermissionResultFromJson(json);

  Map<String, dynamic> toJson() => _$AskDevicePermissionResultToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

/// socket: the computer got it at once; notification: the phone gets a notification to tap (phones can't show a prompt from the background)
enum AskDevicePermissionResultViaEnum {
    /// socket: the computer got it at once; notification: the phone gets a notification to tap (phones can't show a prompt from the background)
@JsonValue(r'socket')
socket(r'socket'),
    /// socket: the computer got it at once; notification: the phone gets a notification to tap (phones can't show a prompt from the background)
@JsonValue(r'notification')
notification(r'notification');

const AskDevicePermissionResultViaEnum(this.value);

final String value;

@override
String toString() => value;
}


