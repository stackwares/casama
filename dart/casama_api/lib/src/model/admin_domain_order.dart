//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'admin_domain_order.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminDomainOrder {
  /// Returns a new [AdminDomainOrder] instance.
  AdminDomainOrder({

    required  this.id,

    required  this.kind,

    required  this.name,

    required  this.priceUsd,

    required  this.status,

    required  this.failure,

    required  this.needsApproval,

    required  this.domainId,

    required  this.createdAt,

    required  this.paidAt,

    required  this.refundedAt,

    required  this.orgId,

    required  this.orgName,

    required  this.attempts,
  });

  @JsonKey(
    
    name: r'id',
    required: true,
    includeIfNull: false,
  )


  final String id;



  @JsonKey(
    
    name: r'kind',
    required: true,
    includeIfNull: false,
  )


  final String kind;



  @JsonKey(
    
    name: r'name',
    required: true,
    includeIfNull: false,
  )


  final String name;



  @JsonKey(
    
    name: r'price_usd',
    required: true,
    includeIfNull: false,
  )


  final num priceUsd;



  @JsonKey(
    
    name: r'status',
    required: true,
    includeIfNull: false,
  )


  final String status;



  @JsonKey(
    
    name: r'failure',
    required: true,
    includeIfNull: true,
  )


  final String? failure;



  @JsonKey(
    
    name: r'needs_approval',
    required: true,
    includeIfNull: false,
  )


  final bool needsApproval;



  @JsonKey(
    
    name: r'domain_id',
    required: true,
    includeIfNull: true,
  )


  final String? domainId;



  @JsonKey(
    
    name: r'created_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime createdAt;



  @JsonKey(
    
    name: r'paid_at',
    required: true,
    includeIfNull: true,
  )


  final DateTime? paidAt;



  @JsonKey(
    
    name: r'refunded_at',
    required: true,
    includeIfNull: true,
  )


  final DateTime? refundedAt;



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
    
    name: r'attempts',
    required: true,
    includeIfNull: false,
  )


  final int attempts;





    @override
    bool operator ==(Object other) => identical(this, other) || other is AdminDomainOrder &&
      other.id == id &&
      other.kind == kind &&
      other.name == name &&
      other.priceUsd == priceUsd &&
      other.status == status &&
      other.failure == failure &&
      other.needsApproval == needsApproval &&
      other.domainId == domainId &&
      other.createdAt == createdAt &&
      other.paidAt == paidAt &&
      other.refundedAt == refundedAt &&
      other.orgId == orgId &&
      other.orgName == orgName &&
      other.attempts == attempts;

    @override
    int get hashCode =>
        id.hashCode +
        kind.hashCode +
        name.hashCode +
        priceUsd.hashCode +
        status.hashCode +
        (failure == null ? 0 : failure.hashCode) +
        needsApproval.hashCode +
        (domainId == null ? 0 : domainId.hashCode) +
        createdAt.hashCode +
        (paidAt == null ? 0 : paidAt.hashCode) +
        (refundedAt == null ? 0 : refundedAt.hashCode) +
        (orgId == null ? 0 : orgId.hashCode) +
        (orgName == null ? 0 : orgName.hashCode) +
        attempts.hashCode;

  factory AdminDomainOrder.fromJson(Map<String, dynamic> json) => _$AdminDomainOrderFromJson(json);

  Map<String, dynamic> toJson() => _$AdminDomainOrderToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

