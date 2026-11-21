//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/workspace_model_default.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'update_organization_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class UpdateOrganizationRequest {
  /// Returns a new [UpdateOrganizationRequest] instance.
  UpdateOrganizationRequest({

     this.name,

     this.icon,

     this.color,

     this.modelDefault,
  });

  @JsonKey(
    
    name: r'name',
    required: false,
    includeIfNull: false,
  )


  final String? name;



  @JsonKey(
    
    name: r'icon',
    required: false,
    includeIfNull: false,
  )


  final String? icon;



  @JsonKey(
    
    name: r'color',
    required: false,
    includeIfNull: false,
  )


  final String? color;



  @JsonKey(
    
    name: r'model_default',
    required: false,
    includeIfNull: false,
  )


  final WorkspaceModelDefault? modelDefault;





    @override
    bool operator ==(Object other) => identical(this, other) || other is UpdateOrganizationRequest &&
      other.name == name &&
      other.icon == icon &&
      other.color == color &&
      other.modelDefault == modelDefault;

    @override
    int get hashCode =>
        name.hashCode +
        (icon == null ? 0 : icon.hashCode) +
        (color == null ? 0 : color.hashCode) +
        (modelDefault == null ? 0 : modelDefault.hashCode);

  factory UpdateOrganizationRequest.fromJson(Map<String, dynamic> json) => _$UpdateOrganizationRequestFromJson(json);

  Map<String, dynamic> toJson() => _$UpdateOrganizationRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

