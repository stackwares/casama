//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/vendor_reading.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'admin_vendor.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminVendor {
  /// Returns a new [AdminVendor] instance.
  AdminVendor({

    required  this.limitValue,

    required  this.period,

    required  this.periodStart,

    required  this.expiresAt,

    required  this.warnAt,

    required  this.enabled,

     this.balanceWarnBelow = 5,

    required  this.billingUrl,

    required  this.impact,

    required  this.vendor,

    required  this.label,

    required  this.kind,

    required  this.unit,

    required  this.latest,

    required  this.history,
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


  final AdminVendorPeriodEnum? period;



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



  @JsonKey(
    
    name: r'billing_url',
    required: true,
    includeIfNull: true,
  )


  final String? billingUrl;



  @JsonKey(
    
    name: r'impact',
    required: true,
    includeIfNull: true,
  )


  final String? impact;



  @JsonKey(
    
    name: r'vendor',
    required: true,
    includeIfNull: false,
  )


  final String vendor;



  @JsonKey(
    
    name: r'label',
    required: true,
    includeIfNull: false,
  )


  final String label;



  @JsonKey(
    
    name: r'kind',
    required: true,
    includeIfNull: false,
  )


  final AdminVendorKindEnum kind;



  @JsonKey(
    
    name: r'unit',
    required: true,
    includeIfNull: false,
  )


  final String unit;



  @JsonKey(
    
    name: r'latest',
    required: true,
    includeIfNull: true,
  )


  final VendorReading? latest;



  @JsonKey(
    
    name: r'history',
    required: true,
    includeIfNull: false,
  )


  final List<VendorReading> history;





    @override
    bool operator ==(Object other) => identical(this, other) || other is AdminVendor &&
      other.limitValue == limitValue &&
      other.period == period &&
      other.periodStart == periodStart &&
      other.expiresAt == expiresAt &&
      other.warnAt == warnAt &&
      other.enabled == enabled &&
      other.balanceWarnBelow == balanceWarnBelow &&
      other.billingUrl == billingUrl &&
      other.impact == impact &&
      other.vendor == vendor &&
      other.label == label &&
      other.kind == kind &&
      other.unit == unit &&
      other.latest == latest &&
      other.history == history;

    @override
    int get hashCode =>
        (limitValue == null ? 0 : limitValue.hashCode) +
        (period == null ? 0 : period.hashCode) +
        (periodStart == null ? 0 : periodStart.hashCode) +
        (expiresAt == null ? 0 : expiresAt.hashCode) +
        warnAt.hashCode +
        enabled.hashCode +
        balanceWarnBelow.hashCode +
        (billingUrl == null ? 0 : billingUrl.hashCode) +
        (impact == null ? 0 : impact.hashCode) +
        vendor.hashCode +
        label.hashCode +
        kind.hashCode +
        unit.hashCode +
        (latest == null ? 0 : latest.hashCode) +
        history.hashCode;

  factory AdminVendor.fromJson(Map<String, dynamic> json) => _$AdminVendorFromJson(json);

  Map<String, dynamic> toJson() => _$AdminVendorToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum AdminVendorPeriodEnum {
@JsonValue(r'day')
day(r'day'),
@JsonValue(r'month')
month(r'month'),
@JsonValue(r'billing_period')
billingPeriod(r'billing_period'),
@JsonValue(r'prepaid')
prepaid(r'prepaid');

const AdminVendorPeriodEnum(this.value);

final String value;

@override
String toString() => value;
}



enum AdminVendorKindEnum {
@JsonValue(r'quota')
quota(r'quota'),
@JsonValue(r'balance')
balance(r'balance'),
@JsonValue(r'renewal')
renewal(r'renewal');

const AdminVendorKindEnum(this.value);

final String value;

@override
String toString() => value;
}


