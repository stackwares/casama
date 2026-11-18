//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/site_host.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'site.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Site {
  /// Returns a new [Site] instance.
  Site({

    required  this.pageId,

    required  this.title,

    required  this.label,

    required  this.addressUrl,

    required  this.url,

    required  this.live,

    required  this.indexable,

    required  this.badge,

    required  this.canIndex,

    required  this.hosts,

    required  this.createdAt,
  });

  @JsonKey(
    
    name: r'page_id',
    required: true,
    includeIfNull: false,
  )


  final String pageId;



  @JsonKey(
    
    name: r'title',
    required: true,
    includeIfNull: false,
  )


  final String title;



  @JsonKey(
    
    name: r'label',
    required: true,
    includeIfNull: true,
  )


  final String? label;



  @JsonKey(
    
    name: r'address_url',
    required: true,
    includeIfNull: true,
  )


  final String? addressUrl;



  @JsonKey(
    
    name: r'url',
    required: true,
    includeIfNull: true,
  )


  final String? url;



  @JsonKey(
    
    name: r'live',
    required: true,
    includeIfNull: false,
  )


  final bool live;



  @JsonKey(
    
    name: r'indexable',
    required: true,
    includeIfNull: false,
  )


  final bool indexable;



  @JsonKey(
    
    name: r'badge',
    required: true,
    includeIfNull: false,
  )


  final bool badge;



  @JsonKey(
    
    name: r'can_index',
    required: true,
    includeIfNull: false,
  )


  final bool canIndex;



  @JsonKey(
    
    name: r'hosts',
    required: true,
    includeIfNull: false,
  )


  final List<SiteHost> hosts;



  @JsonKey(
    
    name: r'created_at',
    required: true,
    includeIfNull: false,
  )


  final DateTime createdAt;





    @override
    bool operator ==(Object other) => identical(this, other) || other is Site &&
      other.pageId == pageId &&
      other.title == title &&
      other.label == label &&
      other.addressUrl == addressUrl &&
      other.url == url &&
      other.live == live &&
      other.indexable == indexable &&
      other.badge == badge &&
      other.canIndex == canIndex &&
      other.hosts == hosts &&
      other.createdAt == createdAt;

    @override
    int get hashCode =>
        pageId.hashCode +
        title.hashCode +
        (label == null ? 0 : label.hashCode) +
        (addressUrl == null ? 0 : addressUrl.hashCode) +
        (url == null ? 0 : url.hashCode) +
        live.hashCode +
        indexable.hashCode +
        badge.hashCode +
        canIndex.hashCode +
        hosts.hashCode +
        createdAt.hashCode;

  factory Site.fromJson(Map<String, dynamic> json) => _$SiteFromJson(json);

  Map<String, dynamic> toJson() => _$SiteToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

