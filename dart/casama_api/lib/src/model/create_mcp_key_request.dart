//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'create_mcp_key_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CreateMcpKeyRequest {
  /// Returns a new [CreateMcpKeyRequest] instance.
  CreateMcpKeyRequest({

    required  this.name,
  });

  @JsonKey(
    
    name: r'name',
    required: true,
    includeIfNull: false,
  )


  final String name;





    @override
    bool operator ==(Object other) => identical(this, other) || other is CreateMcpKeyRequest &&
      other.name == name;

    @override
    int get hashCode =>
        name.hashCode;

  factory CreateMcpKeyRequest.fromJson(Map<String, dynamic> json) => _$CreateMcpKeyRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CreateMcpKeyRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

