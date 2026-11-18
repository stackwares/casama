//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/payment_request.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'payment_request_list.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PaymentRequestList {
  /// Returns a new [PaymentRequestList] instance.
  PaymentRequestList({

    required  this.items,
  });

  @JsonKey(
    
    name: r'items',
    required: true,
    includeIfNull: false,
  )


  final List<PaymentRequest> items;





    @override
    bool operator ==(Object other) => identical(this, other) || other is PaymentRequestList &&
      other.items == items;

    @override
    int get hashCode =>
        items.hashCode;

  factory PaymentRequestList.fromJson(Map<String, dynamic> json) => _$PaymentRequestListFromJson(json);

  Map<String, dynamic> toJson() => _$PaymentRequestListToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

