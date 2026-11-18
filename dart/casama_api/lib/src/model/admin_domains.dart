//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/admin_domains_counts.dart';
import 'package:casama_api/src/model/admin_domain.dart';
import 'package:casama_api/src/model/admin_domain_order.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'admin_domains.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminDomains {
  /// Returns a new [AdminDomains] instance.
  AdminDomains({

    required  this.counts,

    required  this.balanceUsd,

    required  this.orders,

    required  this.domains,
  });

  @JsonKey(
    
    name: r'counts',
    required: true,
    includeIfNull: false,
  )


  final AdminDomainsCounts counts;



  @JsonKey(
    
    name: r'balance_usd',
    required: true,
    includeIfNull: true,
  )


  final num? balanceUsd;



  @JsonKey(
    
    name: r'orders',
    required: true,
    includeIfNull: false,
  )


  final List<AdminDomainOrder> orders;



  @JsonKey(
    
    name: r'domains',
    required: true,
    includeIfNull: false,
  )


  final List<AdminDomain> domains;





    @override
    bool operator ==(Object other) => identical(this, other) || other is AdminDomains &&
      other.counts == counts &&
      other.balanceUsd == balanceUsd &&
      other.orders == orders &&
      other.domains == domains;

    @override
    int get hashCode =>
        counts.hashCode +
        (balanceUsd == null ? 0 : balanceUsd.hashCode) +
        orders.hashCode +
        domains.hashCode;

  factory AdminDomains.fromJson(Map<String, dynamic> json) => _$AdminDomainsFromJson(json);

  Map<String, dynamic> toJson() => _$AdminDomainsToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

