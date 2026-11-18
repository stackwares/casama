//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'sites_config.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SitesConfig {
  /// Returns a new [SitesConfig] instance.
  SitesConfig({

    required  this.zone,

    required  this.customDomains,

    required  this.buyDomains,

    required  this.tlds,
  });

  @JsonKey(
    
    name: r'zone',
    required: true,
    includeIfNull: true,
  )


  final String? zone;



  @JsonKey(
    
    name: r'custom_domains',
    required: true,
    includeIfNull: false,
  )


  final bool customDomains;



  @JsonKey(
    
    name: r'buy_domains',
    required: true,
    includeIfNull: false,
  )


  final bool buyDomains;



  @JsonKey(
    
    name: r'tlds',
    required: true,
    includeIfNull: false,
  )


  final List<String> tlds;





    @override
    bool operator ==(Object other) => identical(this, other) || other is SitesConfig &&
      other.zone == zone &&
      other.customDomains == customDomains &&
      other.buyDomains == buyDomains &&
      other.tlds == tlds;

    @override
    int get hashCode =>
        (zone == null ? 0 : zone.hashCode) +
        customDomains.hashCode +
        buyDomains.hashCode +
        tlds.hashCode;

  factory SitesConfig.fromJson(Map<String, dynamic> json) => _$SitesConfigFromJson(json);

  Map<String, dynamic> toJson() => _$SitesConfigToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

