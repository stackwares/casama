//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'site_host.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SiteHost {
  /// Returns a new [SiteHost] instance.
  SiteHost({

    required  this.id,

    required  this.hostname,

    required  this.kind,

    required  this.isPrimary,

    required  this.status,

    required  this.statusReason,

    required  this.domainId,

    required  this.live,

    required  this.url,
  });

  @JsonKey(
    
    name: r'id',
    required: true,
    includeIfNull: false,
  )


  final String id;



  @JsonKey(
    
    name: r'hostname',
    required: true,
    includeIfNull: false,
  )


  final String hostname;



  @JsonKey(
    
    name: r'kind',
    required: true,
    includeIfNull: false,
  )


  final String kind;



  @JsonKey(
    
    name: r'is_primary',
    required: true,
    includeIfNull: false,
  )


  final bool isPrimary;



  @JsonKey(
    
    name: r'status',
    required: true,
    includeIfNull: false,
  )


  final String status;



  @JsonKey(
    
    name: r'status_reason',
    required: true,
    includeIfNull: true,
  )


  final String? statusReason;



  @JsonKey(
    
    name: r'domain_id',
    required: true,
    includeIfNull: true,
  )


  final String? domainId;



  @JsonKey(
    
    name: r'live',
    required: true,
    includeIfNull: false,
  )


  final bool live;



  @JsonKey(
    
    name: r'url',
    required: true,
    includeIfNull: false,
  )


  final String url;





    @override
    bool operator ==(Object other) => identical(this, other) || other is SiteHost &&
      other.id == id &&
      other.hostname == hostname &&
      other.kind == kind &&
      other.isPrimary == isPrimary &&
      other.status == status &&
      other.statusReason == statusReason &&
      other.domainId == domainId &&
      other.live == live &&
      other.url == url;

    @override
    int get hashCode =>
        id.hashCode +
        hostname.hashCode +
        kind.hashCode +
        isPrimary.hashCode +
        status.hashCode +
        (statusReason == null ? 0 : statusReason.hashCode) +
        (domainId == null ? 0 : domainId.hashCode) +
        live.hashCode +
        url.hashCode;

  factory SiteHost.fromJson(Map<String, dynamic> json) => _$SiteHostFromJson(json);

  Map<String, dynamic> toJson() => _$SiteHostToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

