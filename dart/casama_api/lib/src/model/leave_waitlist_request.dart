//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'leave_waitlist_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class LeaveWaitlistRequest {
  /// Returns a new [LeaveWaitlistRequest] instance.
  LeaveWaitlistRequest({

    required  this.token,
  });

  @JsonKey(
    
    name: r'token',
    required: true,
    includeIfNull: false,
  )


  final String token;





    @override
    bool operator ==(Object other) => identical(this, other) || other is LeaveWaitlistRequest &&
      other.token == token;

    @override
    int get hashCode =>
        token.hashCode;

  factory LeaveWaitlistRequest.fromJson(Map<String, dynamic> json) => _$LeaveWaitlistRequestFromJson(json);

  Map<String, dynamic> toJson() => _$LeaveWaitlistRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

