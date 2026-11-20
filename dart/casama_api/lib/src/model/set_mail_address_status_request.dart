//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'set_mail_address_status_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SetMailAddressStatusRequest {
  /// Returns a new [SetMailAddressStatusRequest] instance.
  SetMailAddressStatusRequest({

    required  this.status,
  });

  @JsonKey(
    
    name: r'status',
    required: true,
    includeIfNull: false,
  )


  final SetMailAddressStatusRequestStatusEnum status;





    @override
    bool operator ==(Object other) => identical(this, other) || other is SetMailAddressStatusRequest &&
      other.status == status;

    @override
    int get hashCode =>
        status.hashCode;

  factory SetMailAddressStatusRequest.fromJson(Map<String, dynamic> json) => _$SetMailAddressStatusRequestFromJson(json);

  Map<String, dynamic> toJson() => _$SetMailAddressStatusRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum SetMailAddressStatusRequestStatusEnum {
@JsonValue(r'active')
active(r'active'),
@JsonValue(r'paused')
paused(r'paused');

const SetMailAddressStatusRequestStatusEnum(this.value);

final String value;

@override
String toString() => value;
}


