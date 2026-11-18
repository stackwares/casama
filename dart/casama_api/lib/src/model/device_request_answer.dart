//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/browser_tab_summary.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'device_request_answer.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class DeviceRequestAnswer {
  /// Returns a new [DeviceRequestAnswer] instance.
  DeviceRequestAnswer({

    required  this.device,

    required  this.result,
  });

      /// The browser that answered
  @JsonKey(
    
    name: r'device',
    required: true,
    includeIfNull: false,
  )


  final String device;



  @JsonKey(
    
    name: r'result',
    required: true,
    includeIfNull: false,
  )


  final BrowserTabSummary result;





    @override
    bool operator ==(Object other) => identical(this, other) || other is DeviceRequestAnswer &&
      other.device == device &&
      other.result == result;

    @override
    int get hashCode =>
        device.hashCode +
        result.hashCode;

  factory DeviceRequestAnswer.fromJson(Map<String, dynamic> json) => _$DeviceRequestAnswerFromJson(json);

  Map<String, dynamic> toJson() => _$DeviceRequestAnswerToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

