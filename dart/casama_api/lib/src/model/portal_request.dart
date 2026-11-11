//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'portal_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PortalRequest {
  /// Returns a new [PortalRequest] instance.
  PortalRequest({

     this.returnUrl,
  });

  @JsonKey(
    
    name: r'return_url',
    required: false,
    includeIfNull: false,
  )


  final String? returnUrl;





    @override
    bool operator ==(Object other) => identical(this, other) || other is PortalRequest &&
      other.returnUrl == returnUrl;

    @override
    int get hashCode =>
        returnUrl.hashCode;

  factory PortalRequest.fromJson(Map<String, dynamic> json) => _$PortalRequestFromJson(json);

  Map<String, dynamic> toJson() => _$PortalRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

