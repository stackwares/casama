//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'vendor_settings.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class VendorSettings {
  /// Returns a new [VendorSettings] instance.
  VendorSettings({

    required  this.limitValue,

    required  this.period,

    required  this.periodStart,

    required  this.expiresAt,

    required  this.warnAt,

    required  this.enabled,

     this.balanceWarnBelow = 5,
  });

          // minimum: 0
  @JsonKey(
    
    name: r'limit_value',
    required: true,
    includeIfNull: true,
  )


  final num? limitValue;



  @JsonKey(
    
    name: r'period',
    required: true,
    includeIfNull: true,
  )


  final VendorSettingsPeriodEnum? period;



  @JsonKey(
    
    name: r'period_start',
    required: true,
    includeIfNull: true,
  )


  final DateTime? periodStart;



  @JsonKey(
    
    name: r'expires_at',
    required: true,
    includeIfNull: true,
  )


  final DateTime? expiresAt;



          // minimum: 0
          // maximum: 1
  @JsonKey(
    
    name: r'warn_at',
    required: true,
    includeIfNull: false,
  )


  final num warnAt;



  @JsonKey(
    
    name: r'enabled',
    required: true,
    includeIfNull: false,
  )


  final bool enabled;



          // minimum: 0
  @JsonKey(
    defaultValue: 5,
    name: r'balance_warn_below',
    required: false,
    includeIfNull: false,
  )


  final num? balanceWarnBelow;





    @override
    bool operator ==(Object other) => identical(this, other) || other is VendorSettings &&
      other.limitValue == limitValue &&
      other.period == period &&
      other.periodStart == periodStart &&
      other.expiresAt == expiresAt &&
      other.warnAt == warnAt &&
      other.enabled == enabled &&
      other.balanceWarnBelow == balanceWarnBelow;

    @override
    int get hashCode =>
        (limitValue == null ? 0 : limitValue.hashCode) +
        (period == null ? 0 : period.hashCode) +
        (periodStart == null ? 0 : periodStart.hashCode) +
        (expiresAt == null ? 0 : expiresAt.hashCode) +
        warnAt.hashCode +
        enabled.hashCode +
        balanceWarnBelow.hashCode;

  factory VendorSettings.fromJson(Map<String, dynamic> json) => _$VendorSettingsFromJson(json);

  Map<String, dynamic> toJson() => _$VendorSettingsToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum VendorSettingsPeriodEnum {
@JsonValue(r'day')
day(r'day'),
@JsonValue(r'month')
month(r'month'),
@JsonValue(r'billing_period')
billingPeriod(r'billing_period'),
@JsonValue(r'prepaid')
prepaid(r'prepaid');

const VendorSettingsPeriodEnum(this.value);

final String value;

@override
String toString() => value;
}


