//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'purchase_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PurchaseRequest {
  /// Returns a new [PurchaseRequest] instance.
  PurchaseRequest({

    required  this.source_,

    required  this.productId,

     this.transactionId,

     this.purchaseToken,
  });

  @JsonKey(
    
    name: r'source',
    required: true,
    includeIfNull: false,
  )


  final PurchaseRequestSource_Enum source_;



  @JsonKey(
    
    name: r'product_id',
    required: true,
    includeIfNull: false,
  )


  final String productId;



      /// App Store transaction id
  @JsonKey(
    
    name: r'transaction_id',
    required: false,
    includeIfNull: false,
  )


  final String? transactionId;



      /// Google Play purchase token
  @JsonKey(
    
    name: r'purchase_token',
    required: false,
    includeIfNull: false,
  )


  final String? purchaseToken;





    @override
    bool operator ==(Object other) => identical(this, other) || other is PurchaseRequest &&
      other.source_ == source_ &&
      other.productId == productId &&
      other.transactionId == transactionId &&
      other.purchaseToken == purchaseToken;

    @override
    int get hashCode =>
        source_.hashCode +
        productId.hashCode +
        transactionId.hashCode +
        purchaseToken.hashCode;

  factory PurchaseRequest.fromJson(Map<String, dynamic> json) => _$PurchaseRequestFromJson(json);

  Map<String, dynamic> toJson() => _$PurchaseRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum PurchaseRequestSource_Enum {
@JsonValue(r'app_store')
appStore(r'app_store'),
@JsonValue(r'google_play')
googlePlay(r'google_play');

const PurchaseRequestSource_Enum(this.value);

final String value;

@override
String toString() => value;
}


