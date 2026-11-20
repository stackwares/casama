//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'set_admin_pin_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SetAdminPinRequest {
  /// Returns a new [SetAdminPinRequest] instance.
  SetAdminPinRequest({

    required  this.pin,
  });

  @JsonKey(
    
    name: r'pin',
    required: true,
    includeIfNull: false,
  )


  final String pin;





    @override
    bool operator ==(Object other) => identical(this, other) || other is SetAdminPinRequest &&
      other.pin == pin;

    @override
    int get hashCode =>
        pin.hashCode;

  factory SetAdminPinRequest.fromJson(Map<String, dynamic> json) => _$SetAdminPinRequestFromJson(json);

  Map<String, dynamic> toJson() => _$SetAdminPinRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

