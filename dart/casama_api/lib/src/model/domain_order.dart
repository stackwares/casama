//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'domain_order.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class DomainOrder {
  /// Returns a new [DomainOrder] instance.
  DomainOrder({

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





    @override
    bool operator ==(Object other) => identical(this, other) || other is DomainOrder &&
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
      other.refundedAt == refundedAt;

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
        (refundedAt == null ? 0 : refundedAt.hashCode);

  factory DomainOrder.fromJson(Map<String, dynamic> json) => _$DomainOrderFromJson(json);

  Map<String, dynamic> toJson() => _$DomainOrderToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

