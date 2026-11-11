//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'plan.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class Plan {
  /// Returns a new [Plan] instance.
  Plan({

    required  this.code,

    required  this.name,

    required  this.interval,

    required  this.limits,

    required  this.priceLabel,

    required  this.web,

    required  this.storeProductIds,
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
    
    name: r'interval',
    required: true,
    includeIfNull: false,
  )


  final PlanIntervalEnum interval;



  @JsonKey(
    
    name: r'limits',
    required: true,
    includeIfNull: false,
  )


  final Map<String, num> limits;



  @JsonKey(
    
    name: r'price_label',
    required: true,
    includeIfNull: true,
  )


  final String? priceLabel;



  @JsonKey(
    
    name: r'web',
    required: true,
    includeIfNull: false,
  )


  final bool web;



  @JsonKey(
    
    name: r'store_product_ids',
    required: true,
    includeIfNull: false,
  )


  final Map<String, String> storeProductIds;





    @override
    bool operator ==(Object other) => identical(this, other) || other is Plan &&
      other.code == code &&
      other.name == name &&
      other.interval == interval &&
      other.limits == limits &&
      other.priceLabel == priceLabel &&
      other.web == web &&
      other.storeProductIds == storeProductIds;

    @override
    int get hashCode =>
        code.hashCode +
        name.hashCode +
        interval.hashCode +
        limits.hashCode +
        (priceLabel == null ? 0 : priceLabel.hashCode) +
        web.hashCode +
        storeProductIds.hashCode;

  factory Plan.fromJson(Map<String, dynamic> json) => _$PlanFromJson(json);

  Map<String, dynamic> toJson() => _$PlanToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum PlanIntervalEnum {
@JsonValue(r'none')
none(r'none'),
@JsonValue(r'month')
month(r'month'),
@JsonValue(r'year')
year(r'year');

const PlanIntervalEnum(this.value);

final String value;

@override
String toString() => value;
}


