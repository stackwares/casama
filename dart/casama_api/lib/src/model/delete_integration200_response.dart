//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'delete_integration200_response.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class DeleteIntegration200Response {
  /// Returns a new [DeleteIntegration200Response] instance.
  DeleteIntegration200Response({

    required  this.ok,
  });

  @JsonKey(
    
    name: r'ok',
    required: true,
    includeIfNull: false,
  )


  final bool ok;





    @override
    bool operator ==(Object other) => identical(this, other) || other is DeleteIntegration200Response &&
      other.ok == ok;

    @override
    int get hashCode =>
        ok.hashCode;

  factory DeleteIntegration200Response.fromJson(Map<String, dynamic> json) => _$DeleteIntegration200ResponseFromJson(json);

  Map<String, dynamic> toJson() => _$DeleteIntegration200ResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

