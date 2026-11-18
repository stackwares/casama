//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'approve_link_sign_in_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ApproveLinkSignInRequest {
  /// Returns a new [ApproveLinkSignInRequest] instance.
  ApproveLinkSignInRequest({

    required  this.userCode,
  });

  @JsonKey(
    
    name: r'user_code',
    required: true,
    includeIfNull: false,
  )


  final String userCode;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ApproveLinkSignInRequest &&
      other.userCode == userCode;

    @override
    int get hashCode =>
        userCode.hashCode;

  factory ApproveLinkSignInRequest.fromJson(Map<String, dynamic> json) => _$ApproveLinkSignInRequestFromJson(json);

  Map<String, dynamic> toJson() => _$ApproveLinkSignInRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

