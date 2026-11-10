//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'set_encryption_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SetEncryptionRequest {
  /// Returns a new [SetEncryptionRequest] instance.
  SetEncryptionRequest({

    required  this.enabled,
  });

  @JsonKey(
    
    name: r'enabled',
    required: true,
    includeIfNull: false,
  )


  final bool enabled;





    @override
    bool operator ==(Object other) => identical(this, other) || other is SetEncryptionRequest &&
      other.enabled == enabled;

    @override
    int get hashCode =>
        enabled.hashCode;

  factory SetEncryptionRequest.fromJson(Map<String, dynamic> json) => _$SetEncryptionRequestFromJson(json);

  Map<String, dynamic> toJson() => _$SetEncryptionRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

