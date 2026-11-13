//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'admin_credit_pack.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminCreditPack {
  /// Returns a new [AdminCreditPack] instance.
  AdminCreditPack({

    required  this.code,

    required  this.name,

    required  this.creditsUsd,

    required  this.active,

    required  this.priceLabel,

    required  this.storeProductIds,

    required  this.dodoProductId,
  });

  @JsonKey(
    
    name: r'code',
    required: true,
    includeIfNull: false,
  )


  final String code;



  @JsonKey(
    
    name: r'name',
    required: true,
    includeIfNull: false,
  )


  final String name;



  @JsonKey(
    
    name: r'credits_usd',
    required: true,
    includeIfNull: false,
  )


  final num creditsUsd;



  @JsonKey(
    
    name: r'active',
    required: true,
    includeIfNull: false,
  )


  final bool active;



  @JsonKey(
    
    name: r'price_label',
    required: true,
    includeIfNull: true,
  )


  final String? priceLabel;



  @JsonKey(
    
    name: r'store_product_ids',
    required: true,
    includeIfNull: false,
  )


  final Map<String, String> storeProductIds;



  @JsonKey(
    
    name: r'dodo_product_id',
    required: true,
    includeIfNull: true,
  )


  final String? dodoProductId;





    @override
    bool operator ==(Object other) => identical(this, other) || other is AdminCreditPack &&
      other.code == code &&
      other.name == name &&
      other.creditsUsd == creditsUsd &&
      other.active == active &&
      other.priceLabel == priceLabel &&
      other.storeProductIds == storeProductIds &&
      other.dodoProductId == dodoProductId;

    @override
    int get hashCode =>
        code.hashCode +
        name.hashCode +
        creditsUsd.hashCode +
        active.hashCode +
        (priceLabel == null ? 0 : priceLabel.hashCode) +
        storeProductIds.hashCode +
        (dodoProductId == null ? 0 : dodoProductId.hashCode);

  factory AdminCreditPack.fromJson(Map<String, dynamic> json) => _$AdminCreditPackFromJson(json);

  Map<String, dynamic> toJson() => _$AdminCreditPackToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

