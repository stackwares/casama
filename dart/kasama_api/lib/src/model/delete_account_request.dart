//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'delete_account_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class DeleteAccountRequest {
  /// Returns a new [DeleteAccountRequest] instance.
  DeleteAccountRequest({

    required  this.confirmEmail,
  });

      /// The account's email, to confirm
  @JsonKey(
    
    name: r'confirm_email',
    required: true,
    includeIfNull: false,
  )


  final String confirmEmail;





    @override
    bool operator ==(Object other) => identical(this, other) || other is DeleteAccountRequest &&
      other.confirmEmail == confirmEmail;

    @override
    int get hashCode =>
        confirmEmail.hashCode;

  factory DeleteAccountRequest.fromJson(Map<String, dynamic> json) => _$DeleteAccountRequestFromJson(json);

  Map<String, dynamic> toJson() => _$DeleteAccountRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

