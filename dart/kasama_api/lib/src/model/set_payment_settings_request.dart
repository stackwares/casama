//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:kasama_api/src/model/set_payment_settings_request_cardholder.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'set_payment_settings_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SetPaymentSettingsRequest {
  /// Returns a new [SetPaymentSettingsRequest] instance.
  SetPaymentSettingsRequest({

    required  this.secretKey,

    required  this.webhookSecret,

    required  this.cardholder,

     this.monthlyCapUsd,

     this.botMonthlyCapUsd,
  });

  @JsonKey(
    
    name: r'secret_key',
    required: true,
    includeIfNull: false,
  )


  final String secretKey;



  @JsonKey(
    
    name: r'webhook_secret',
    required: true,
    includeIfNull: false,
  )


  final String webhookSecret;



  @JsonKey(
    
    name: r'cardholder',
    required: true,
    includeIfNull: false,
  )


  final SetPaymentSettingsRequestCardholder cardholder;



          // minimum: 0
          // maximum: 100000
  @JsonKey(
    
    name: r'monthly_cap_usd',
    required: false,
    includeIfNull: false,
  )


  final num? monthlyCapUsd;



          // minimum: 0
          // maximum: 100000
  @JsonKey(
    
    name: r'bot_monthly_cap_usd',
    required: false,
    includeIfNull: false,
  )


  final num? botMonthlyCapUsd;





    @override
    bool operator ==(Object other) => identical(this, other) || other is SetPaymentSettingsRequest &&
      other.secretKey == secretKey &&
      other.webhookSecret == webhookSecret &&
      other.cardholder == cardholder &&
      other.monthlyCapUsd == monthlyCapUsd &&
      other.botMonthlyCapUsd == botMonthlyCapUsd;

    @override
    int get hashCode =>
        secretKey.hashCode +
        webhookSecret.hashCode +
        cardholder.hashCode +
        monthlyCapUsd.hashCode +
        botMonthlyCapUsd.hashCode;

  factory SetPaymentSettingsRequest.fromJson(Map<String, dynamic> json) => _$SetPaymentSettingsRequestFromJson(json);

  Map<String, dynamic> toJson() => _$SetPaymentSettingsRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

