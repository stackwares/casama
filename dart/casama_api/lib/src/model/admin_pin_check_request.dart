//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'admin_pin_check_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminPinCheckRequest {
  /// Returns a new [AdminPinCheckRequest] instance.
  AdminPinCheckRequest({

    required  this.pin,
  });

  @JsonKey(
    
    name: r'pin',
    required: true,
    includeIfNull: false,
  )


  final String pin;





    @override
    bool operator ==(Object other) => identical(this, other) || other is AdminPinCheckRequest &&
      other.pin == pin;

    @override
    int get hashCode =>
        pin.hashCode;

  factory AdminPinCheckRequest.fromJson(Map<String, dynamic> json) => _$AdminPinCheckRequestFromJson(json);

  Map<String, dynamic> toJson() => _$AdminPinCheckRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

