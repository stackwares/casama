//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'mark_teach_secret_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class MarkTeachSecretRequest {
  /// Returns a new [MarkTeachSecretRequest] instance.
  MarkTeachSecretRequest({

    required  this.secretName,
  });

  @JsonKey(
    
    name: r'secret_name',
    required: true,
    includeIfNull: false,
  )


  final String secretName;





    @override
    bool operator ==(Object other) => identical(this, other) || other is MarkTeachSecretRequest &&
      other.secretName == secretName;

    @override
    int get hashCode =>
        secretName.hashCode;

  factory MarkTeachSecretRequest.fromJson(Map<String, dynamic> json) => _$MarkTeachSecretRequestFromJson(json);

  Map<String, dynamic> toJson() => _$MarkTeachSecretRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

