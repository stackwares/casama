//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'domain_search_result.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class DomainSearchResult {
  /// Returns a new [DomainSearchResult] instance.
  DomainSearchResult({

    required  this.name,

    required  this.available,

    required  this.reason,

    required  this.priceUsd,

    required  this.renewPriceUsd,
  });

  @JsonKey(
    
    name: r'name',
    required: true,
    includeIfNull: false,
  )


  final String name;



  @JsonKey(
    
    name: r'available',
    required: true,
    includeIfNull: false,
  )


  final bool available;



  @JsonKey(
    
    name: r'reason',
    required: true,
    includeIfNull: true,
  )


  final String? reason;



  @JsonKey(
    
    name: r'price_usd',
    required: true,
    includeIfNull: true,
  )


  final num? priceUsd;



  @JsonKey(
    
    name: r'renew_price_usd',
    required: true,
    includeIfNull: true,
  )


  final num? renewPriceUsd;





    @override
    bool operator ==(Object other) => identical(this, other) || other is DomainSearchResult &&
      other.name == name &&
      other.available == available &&
      other.reason == reason &&
      other.priceUsd == priceUsd &&
      other.renewPriceUsd == renewPriceUsd;

    @override
    int get hashCode =>
        name.hashCode +
        available.hashCode +
        (reason == null ? 0 : reason.hashCode) +
        (priceUsd == null ? 0 : priceUsd.hashCode) +
        (renewPriceUsd == null ? 0 : renewPriceUsd.hashCode);

  factory DomainSearchResult.fromJson(Map<String, dynamic> json) => _$DomainSearchResultFromJson(json);

  Map<String, dynamic> toJson() => _$DomainSearchResultToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

