//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'support_web_session_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SupportWebSessionRequest {
  /// Returns a new [SupportWebSessionRequest] instance.
  SupportWebSessionRequest({

    required  this.turnstileToken,
  });

  @JsonKey(
    
    name: r'turnstile_token',
    required: true,
    includeIfNull: false,
  )


  final String turnstileToken;





    @override
    bool operator ==(Object other) => identical(this, other) || other is SupportWebSessionRequest &&
      other.turnstileToken == turnstileToken;

    @override
    int get hashCode =>
        turnstileToken.hashCode;

  factory SupportWebSessionRequest.fromJson(Map<String, dynamic> json) => _$SupportWebSessionRequestFromJson(json);

  Map<String, dynamic> toJson() => _$SupportWebSessionRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

