//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'checkout_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CheckoutRequest {
  /// Returns a new [CheckoutRequest] instance.
  CheckoutRequest({

     this.planCode,

     this.packCode,

     this.returnUrl,
  });

  @JsonKey(
    
    name: r'plan_code',
    required: false,
    includeIfNull: false,
  )


  final String? planCode;



  @JsonKey(
    
    name: r'pack_code',
    required: false,
    includeIfNull: false,
  )


  final String? packCode;



  @JsonKey(
    
    name: r'return_url',
    required: false,
    includeIfNull: false,
  )


  final String? returnUrl;





    @override
    bool operator ==(Object other) => identical(this, other) || other is CheckoutRequest &&
      other.planCode == planCode &&
      other.packCode == packCode &&
      other.returnUrl == returnUrl;

    @override
    int get hashCode =>
        planCode.hashCode +
        packCode.hashCode +
        returnUrl.hashCode;

  factory CheckoutRequest.fromJson(Map<String, dynamic> json) => _$CheckoutRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CheckoutRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

