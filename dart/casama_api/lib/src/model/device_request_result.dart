//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'device_request_result.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class DeviceRequestResult {
  /// Returns a new [DeviceRequestResult] instance.
  DeviceRequestResult({

    required  this.ok,

     this.result,

     this.error,
  });

  @JsonKey(
    
    name: r'ok',
    required: true,
    includeIfNull: false,
  )


  final bool ok;



  @JsonKey(
    
    name: r'result',
    required: false,
    includeIfNull: false,
  )


  final Map<String, Object?>? result;



  @JsonKey(
    
    name: r'error',
    required: false,
    includeIfNull: false,
  )


  final String? error;





    @override
    bool operator ==(Object other) => identical(this, other) || other is DeviceRequestResult &&
      other.ok == ok &&
      other.result == result &&
      other.error == error;

    @override
    int get hashCode =>
        ok.hashCode +
        result.hashCode +
        error.hashCode;

  factory DeviceRequestResult.fromJson(Map<String, dynamic> json) => _$DeviceRequestResultFromJson(json);

  Map<String, dynamic> toJson() => _$DeviceRequestResultToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

