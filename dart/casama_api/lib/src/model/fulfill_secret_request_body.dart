//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'fulfill_secret_request_body.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class FulfillSecretRequestBody {
  /// Returns a new [FulfillSecretRequestBody] instance.
  FulfillSecretRequestBody({

    required  this.value,
  });

      /// Stored in Vault; never returned, logged or shown to the bot
  @JsonKey(
    
    name: r'value',
    required: true,
    includeIfNull: false,
  )


  final String value;





    @override
    bool operator ==(Object other) => identical(this, other) || other is FulfillSecretRequestBody &&
      other.value == value;

    @override
    int get hashCode =>
        value.hashCode;

  factory FulfillSecretRequestBody.fromJson(Map<String, dynamic> json) => _$FulfillSecretRequestBodyFromJson(json);

  Map<String, dynamic> toJson() => _$FulfillSecretRequestBodyToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

