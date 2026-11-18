//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'save_credit_pack_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SaveCreditPackRequest {
  /// Returns a new [SaveCreditPackRequest] instance.
  SaveCreditPackRequest({

     this.name,

     this.creditsUsd,

     this.active,

     this.priceLabel,

     this.storeProductIds,

     this.dodoProductId,
  });

  @JsonKey(
    
    name: r'name',
    required: false,
    includeIfNull: false,
  )


  final String? name;



          // minimum: 0
          // maximum: 10000
  @JsonKey(
    
    name: r'credits_usd',
    required: false,
    includeIfNull: false,
  )


  final num? creditsUsd;



  @JsonKey(
    
    name: r'active',
    required: false,
    includeIfNull: false,
  )


  final bool? active;



  @JsonKey(
    
    name: r'price_label',
    required: false,
    includeIfNull: false,
  )


  final String? priceLabel;



  @JsonKey(
    
    name: r'store_product_ids',
    required: false,
    includeIfNull: false,
  )


  final Map<String, String>? storeProductIds;



  @JsonKey(
    
    name: r'dodo_product_id',
    required: false,
    includeIfNull: false,
  )


  final String? dodoProductId;





    @override
    bool operator ==(Object other) => identical(this, other) || other is SaveCreditPackRequest &&
      other.name == name &&
      other.creditsUsd == creditsUsd &&
      other.active == active &&
      other.priceLabel == priceLabel &&
      other.storeProductIds == storeProductIds &&
      other.dodoProductId == dodoProductId;

    @override
    int get hashCode =>
        name.hashCode +
        creditsUsd.hashCode +
        active.hashCode +
        (priceLabel == null ? 0 : priceLabel.hashCode) +
        storeProductIds.hashCode +
        (dodoProductId == null ? 0 : dodoProductId.hashCode);

  factory SaveCreditPackRequest.fromJson(Map<String, dynamic> json) => _$SaveCreditPackRequestFromJson(json);

  Map<String, dynamic> toJson() => _$SaveCreditPackRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

