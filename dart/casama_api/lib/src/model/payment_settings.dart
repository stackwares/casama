//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'payment_settings.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PaymentSettings {
  /// Returns a new [PaymentSettings] instance.
  PaymentSettings({

    required  this.connected,

    required  this.provider,

    required  this.monthlyCapUsd,

    required  this.botMonthlyCapUsd,

    required  this.spentThisMonthUsd,

    required  this.webhookUrl,
  });

  @JsonKey(
    
    name: r'connected',
    required: true,
    includeIfNull: false,
  )


  final bool connected;



  @JsonKey(
    
    name: r'provider',
    required: true,
    includeIfNull: true,
  )


  final PaymentSettingsProviderEnum? provider;



  @JsonKey(
    
    name: r'monthly_cap_usd',
    required: true,
    includeIfNull: false,
  )


  final num monthlyCapUsd;



  @JsonKey(
    
    name: r'bot_monthly_cap_usd',
    required: true,
    includeIfNull: false,
  )


  final num botMonthlyCapUsd;



  @JsonKey(
    
    name: r'spent_this_month_usd',
    required: true,
    includeIfNull: false,
  )


  final num spentThisMonthUsd;



  @JsonKey(
    
    name: r'webhook_url',
    required: true,
    includeIfNull: true,
  )


  final String? webhookUrl;





    @override
    bool operator ==(Object other) => identical(this, other) || other is PaymentSettings &&
      other.connected == connected &&
      other.provider == provider &&
      other.monthlyCapUsd == monthlyCapUsd &&
      other.botMonthlyCapUsd == botMonthlyCapUsd &&
      other.spentThisMonthUsd == spentThisMonthUsd &&
      other.webhookUrl == webhookUrl;

    @override
    int get hashCode =>
        connected.hashCode +
        (provider == null ? 0 : provider.hashCode) +
        monthlyCapUsd.hashCode +
        botMonthlyCapUsd.hashCode +
        spentThisMonthUsd.hashCode +
        (webhookUrl == null ? 0 : webhookUrl.hashCode);

  factory PaymentSettings.fromJson(Map<String, dynamic> json) => _$PaymentSettingsFromJson(json);

  Map<String, dynamic> toJson() => _$PaymentSettingsToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum PaymentSettingsProviderEnum {
@JsonValue(r'stripe')
stripe(r'stripe');

const PaymentSettingsProviderEnum(this.value);

final String value;

@override
String toString() => value;
}


