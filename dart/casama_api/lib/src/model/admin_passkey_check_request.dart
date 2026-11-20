//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'admin_passkey_check_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminPasskeyCheckRequest {
  /// Returns a new [AdminPasskeyCheckRequest] instance.
  AdminPasskeyCheckRequest({

    required  this.token,
  });

  @JsonKey(
    
    name: r'token',
    required: true,
    includeIfNull: false,
  )


  final String token;





    @override
    bool operator ==(Object other) => identical(this, other) || other is AdminPasskeyCheckRequest &&
      other.token == token;

    @override
    int get hashCode =>
        token.hashCode;

  factory AdminPasskeyCheckRequest.fromJson(Map<String, dynamic> json) => _$AdminPasskeyCheckRequestFromJson(json);

  Map<String, dynamic> toJson() => _$AdminPasskeyCheckRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

