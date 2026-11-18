//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'admin_domain.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminDomain {
  /// Returns a new [AdminDomain] instance.
  AdminDomain({

    required  this.id,

    required  this.name,

    required  this.kind,

    required  this.orgId,

    required  this.orgName,

    required  this.registrarStatus,

    required  this.expiresAt,

    required  this.suspended,

    required  this.createdAt,
  });

  @JsonKey(
    
    name: r'id',
    required: true,
    includeIfNull: false,
  )


  final String id;



  @JsonKey(
    
    name: r'name',
    required: true,
    includeIfNull: false,
  )


  final String name;



  @JsonKey(
    
    name: r'kind',
    required: true,
    includeIfNull: false,
  )


  final String kind;



  @JsonKey(
    
    name: r'org_id',
    required: true,
    includeIfNull: true,
  )


  final String? orgId;



  @JsonKey(
    
    name: r'org_name',
    required: true,
    includeIfNull: true,
  )


  final String? orgName;



  @JsonKey(
    
    name: r'registrar_status',
    required: true,
    includeIfNull: true,
  )


  final String? registrarStatus;



  @JsonKey(
    
    name: r'expires_at',
    required: true,
    includeIfNull: true,
  )


  final DateTime? expiresAt;



  @JsonKey(
    
    name: r'suspended',
    required: true,
    includeIfNull: false,
  )


  final bool suspended;



  @JsonKey(
    
    name: r'created_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime createdAt;





    @override
    bool operator ==(Object other) => identical(this, other) || other is AdminDomain &&
      other.id == id &&
      other.name == name &&
      other.kind == kind &&
      other.orgId == orgId &&
      other.orgName == orgName &&
      other.registrarStatus == registrarStatus &&
      other.expiresAt == expiresAt &&
      other.suspended == suspended &&
      other.createdAt == createdAt;

    @override
    int get hashCode =>
        id.hashCode +
        name.hashCode +
        kind.hashCode +
        (orgId == null ? 0 : orgId.hashCode) +
        (orgName == null ? 0 : orgName.hashCode) +
        (registrarStatus == null ? 0 : registrarStatus.hashCode) +
        (expiresAt == null ? 0 : expiresAt.hashCode) +
        suspended.hashCode +
        createdAt.hashCode;

  factory AdminDomain.fromJson(Map<String, dynamic> json) => _$AdminDomainFromJson(json);

  Map<String, dynamic> toJson() => _$AdminDomainToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

