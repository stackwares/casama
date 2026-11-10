//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
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





    @override
    bool operator ==(Object other) => identical(this, other) || other is UpdateOrganizationRequest &&
      other.name == name &&
      other.icon == icon &&
      other.color == color;

    @override
    int get hashCode =>
        name.hashCode +
        (icon == null ? 0 : icon.hashCode) +
        (color == null ? 0 : color.hashCode);

  factory UpdateOrganizationRequest.fromJson(Map<String, dynamic> json) => _$UpdateOrganizationRequestFromJson(json);

  Map<String, dynamic> toJson() => _$UpdateOrganizationRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

