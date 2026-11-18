//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/domain_record.dart';
import 'package:casama_api/src/model/site_host.dart';
import 'package:casama_api/src/model/domain_event.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'domain.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Domain {
  /// Returns a new [Domain] instance.
  Domain({

    required  this.id,

    required  this.name,

    required  this.kind,

    required  this.target,

    required  this.dnsProvider,

     this.dnsProviderName,

    required  this.pageId,

    required  this.pageTitle,

    required  this.state,

    required  this.live,

    required  this.hosts,

    required  this.records,

    required  this.expiresAt,

    required  this.autoRenew,

    required  this.registrarStatus,

    required  this.renewPriceUsd,

    required  this.locked,

    required  this.transferAfter,

    required  this.registrantVerified,

    required  this.checkedAt,

    required  this.createdAt,

     this.events,
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
    
    name: r'target',
    required: true,
    includeIfNull: false,
  )


  final String target;



  @JsonKey(
    
    name: r'dns_provider',
    required: true,
    includeIfNull: true,
  )


  final String? dnsProvider;



  @JsonKey(
    
    name: r'dns_provider_name',
    required: false,
    includeIfNull: false,
  )


  final String? dnsProviderName;



  @JsonKey(
    
    name: r'page_id',
    required: true,
    includeIfNull: true,
  )


  final String? pageId;



  @JsonKey(
    
    name: r'page_title',
    required: true,
    includeIfNull: true,
  )


  final String? pageTitle;



  @JsonKey(
    
    name: r'state',
    required: true,
    includeIfNull: false,
  )


  final String state;



  @JsonKey(
    
    name: r'live',
    required: true,
    includeIfNull: false,
  )


  final bool live;



  @JsonKey(
    
    name: r'hosts',
    required: true,
    includeIfNull: false,
  )


  final List<SiteHost> hosts;



  @JsonKey(
    
    name: r'records',
    required: true,
    includeIfNull: false,
  )


  final List<DomainRecord> records;



  @JsonKey(
    
    name: r'expires_at',
    required: true,
    includeIfNull: true,
  )


  final DateTime? expiresAt;



  @JsonKey(
    
    name: r'auto_renew',
    required: true,
    includeIfNull: false,
  )


  final bool autoRenew;



  @JsonKey(
    
    name: r'registrar_status',
    required: true,
    includeIfNull: true,
  )


  final String? registrarStatus;



  @JsonKey(
    
    name: r'renew_price_usd',
    required: true,
    includeIfNull: true,
  )


  final num? renewPriceUsd;



  @JsonKey(
    
    name: r'locked',
    required: true,
    includeIfNull: false,
  )


  final bool locked;



  @JsonKey(
    
    name: r'transfer_after',
    required: true,
    includeIfNull: true,
  )


  final DateTime? transferAfter;



  @JsonKey(
    
    name: r'registrant_verified',
    required: true,
    includeIfNull: true,
  )


  final bool? registrantVerified;



  @JsonKey(
    
    name: r'checked_at',
    required: true,
    includeIfNull: true,
  )


  final DateTime? checkedAt;



  @JsonKey(
    
    name: r'created_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime createdAt;



  @JsonKey(
    
    name: r'events',
    required: false,
    includeIfNull: false,
  )


  final List<DomainEvent>? events;





    @override
    bool operator ==(Object other) => identical(this, other) || other is Domain &&
      other.id == id &&
      other.name == name &&
      other.kind == kind &&
      other.target == target &&
      other.dnsProvider == dnsProvider &&
      other.dnsProviderName == dnsProviderName &&
      other.pageId == pageId &&
      other.pageTitle == pageTitle &&
      other.state == state &&
      other.live == live &&
      other.hosts == hosts &&
      other.records == records &&
      other.expiresAt == expiresAt &&
      other.autoRenew == autoRenew &&
      other.registrarStatus == registrarStatus &&
      other.renewPriceUsd == renewPriceUsd &&
      other.locked == locked &&
      other.transferAfter == transferAfter &&
      other.registrantVerified == registrantVerified &&
      other.checkedAt == checkedAt &&
      other.createdAt == createdAt &&
      other.events == events;

    @override
    int get hashCode =>
        id.hashCode +
        name.hashCode +
        kind.hashCode +
        target.hashCode +
        (dnsProvider == null ? 0 : dnsProvider.hashCode) +
        (dnsProviderName == null ? 0 : dnsProviderName.hashCode) +
        (pageId == null ? 0 : pageId.hashCode) +
        (pageTitle == null ? 0 : pageTitle.hashCode) +
        state.hashCode +
        live.hashCode +
        hosts.hashCode +
        records.hashCode +
        (expiresAt == null ? 0 : expiresAt.hashCode) +
        autoRenew.hashCode +
        (registrarStatus == null ? 0 : registrarStatus.hashCode) +
        (renewPriceUsd == null ? 0 : renewPriceUsd.hashCode) +
        locked.hashCode +
        (transferAfter == null ? 0 : transferAfter.hashCode) +
        (registrantVerified == null ? 0 : registrantVerified.hashCode) +
        (checkedAt == null ? 0 : checkedAt.hashCode) +
        createdAt.hashCode +
        events.hashCode;

  factory Domain.fromJson(Map<String, dynamic> json) => _$DomainFromJson(json);

  Map<String, dynamic> toJson() => _$DomainToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

