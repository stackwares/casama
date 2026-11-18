//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'create_device_request_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CreateDeviceRequestRequest {
  /// Returns a new [CreateDeviceRequestRequest] instance.
  CreateDeviceRequestRequest({

    required  this.kind,
  });

  @JsonKey(
    
    name: r'kind',
    required: true,
    includeIfNull: false,
  )


  final CreateDeviceRequestRequestKindEnum kind;





    @override
    bool operator ==(Object other) => identical(this, other) || other is CreateDeviceRequestRequest &&
      other.kind == kind;

    @override
    int get hashCode =>
        kind.hashCode;

  factory CreateDeviceRequestRequest.fromJson(Map<String, dynamic> json) => _$CreateDeviceRequestRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CreateDeviceRequestRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum CreateDeviceRequestRequestKindEnum {
@JsonValue(r'browser_tab')
browserTab(r'browser_tab');

const CreateDeviceRequestRequestKindEnum(this.value);

final String value;

@override
String toString() => value;
}


