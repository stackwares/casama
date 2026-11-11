//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'admin_service.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminService {
  /// Returns a new [AdminService] instance.
  AdminService({

    required  this.name,

    required  this.configured,

    required  this.healthy,

    required  this.detail,
  });

  @JsonKey(
    
    name: r'name',
    required: true,
    includeIfNull: false,
  )


  final String name;



  @JsonKey(
    
    name: r'configured',
    required: true,
    includeIfNull: false,
  )


  final bool configured;



  @JsonKey(
    
    name: r'healthy',
    required: true,
    includeIfNull: true,
  )


  final bool? healthy;



  @JsonKey(
    
    name: r'detail',
    required: true,
    includeIfNull: false,
  )


  final String detail;





    @override
    bool operator ==(Object other) => identical(this, other) || other is AdminService &&
      other.name == name &&
      other.configured == configured &&
      other.healthy == healthy &&
      other.detail == detail;

    @override
    int get hashCode =>
        name.hashCode +
        configured.hashCode +
        (healthy == null ? 0 : healthy.hashCode) +
        detail.hashCode;

  factory AdminService.fromJson(Map<String, dynamic> json) => _$AdminServiceFromJson(json);

  Map<String, dynamic> toJson() => _$AdminServiceToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

