//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/domain_order.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'domain_checkout_result.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class DomainCheckoutResult {
  /// Returns a new [DomainCheckoutResult] instance.
  DomainCheckoutResult({

    required  this.order,

    required  this.checkoutUrl,
  });

  @JsonKey(
    
    name: r'order',
    required: true,
    includeIfNull: false,
  )


  final DomainOrder order;



  @JsonKey(
    
    name: r'checkout_url',
    required: true,
    includeIfNull: true,
  )


  final String? checkoutUrl;





    @override
    bool operator ==(Object other) => identical(this, other) || other is DomainCheckoutResult &&
      other.order == order &&
      other.checkoutUrl == checkoutUrl;

    @override
    int get hashCode =>
        order.hashCode +
        (checkoutUrl == null ? 0 : checkoutUrl.hashCode);

  factory DomainCheckoutResult.fromJson(Map<String, dynamic> json) => _$DomainCheckoutResultFromJson(json);

  Map<String, dynamic> toJson() => _$DomainCheckoutResultToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

