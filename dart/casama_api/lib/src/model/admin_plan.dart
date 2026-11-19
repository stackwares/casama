//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'admin_plan.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminPlan {
  /// Returns a new [AdminPlan] instance.
  AdminPlan({

    required  this.code,

    required  this.name,

    required  this.interval,

    required  this.active,

    required  this.sort,

    required  this.priceLabel,

    required  this.limits,

    required  this.creditGate,

    required  this.storeProductIds,

    required  this.dodoProductId,

    required  this.paywallDefault,

    required  this.paywallPopular,

    required  this.workspaces,
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


  final AdminPlanIntervalEnum interval;



  @JsonKey(
    
    name: r'active',
    required: true,
    includeIfNull: false,
  )


  final bool active;



  @JsonKey(
    
    name: r'sort',
    required: true,
    includeIfNull: false,
  )


  final int sort;



  @JsonKey(
    
    name: r'price_label',
    required: true,
    includeIfNull: true,
  )


  final String? priceLabel;



  @JsonKey(
    
    name: r'limits',
    required: true,
    includeIfNull: false,
  )


  final Map<String, num> limits;



      /// Runs on Casama's keys stop when the workspace's credits run out
  @JsonKey(
    
    name: r'credit_gate',
    required: true,
    includeIfNull: false,
  )


  final bool creditGate;



  @JsonKey(
    
    name: r'store_product_ids',
    required: true,
    includeIfNull: false,
  )


  final Map<String, String> storeProductIds;



  @JsonKey(
    
    name: r'dodo_product_id',
    required: true,
    includeIfNull: true,
  )


  final String? dodoProductId;



      /// The paywall opens on this plan: its tier for a Free workspace, its period for everyone
  @JsonKey(
    
    name: r'paywall_default',
    required: true,
    includeIfNull: false,
  )


  final bool paywallDefault;



      /// Marked \"Most popular\" on the paywall
  @JsonKey(
    
    name: r'paywall_popular',
    required: true,
    includeIfNull: false,
  )


  final bool paywallPopular;



      /// Workspaces on this plan now
  @JsonKey(
    
    name: r'workspaces',
    required: true,
    includeIfNull: false,
  )


  final int workspaces;





    @override
    bool operator ==(Object other) => identical(this, other) || other is AdminPlan &&
      other.code == code &&
      other.name == name &&
      other.interval == interval &&
      other.active == active &&
      other.sort == sort &&
      other.priceLabel == priceLabel &&
      other.limits == limits &&
      other.creditGate == creditGate &&
      other.storeProductIds == storeProductIds &&
      other.dodoProductId == dodoProductId &&
      other.paywallDefault == paywallDefault &&
      other.paywallPopular == paywallPopular &&
      other.workspaces == workspaces;

    @override
    int get hashCode =>
        code.hashCode +
        name.hashCode +
        interval.hashCode +
        active.hashCode +
        sort.hashCode +
        (priceLabel == null ? 0 : priceLabel.hashCode) +
        limits.hashCode +
        creditGate.hashCode +
        storeProductIds.hashCode +
        (dodoProductId == null ? 0 : dodoProductId.hashCode) +
        paywallDefault.hashCode +
        paywallPopular.hashCode +
        workspaces.hashCode;

  factory AdminPlan.fromJson(Map<String, dynamic> json) => _$AdminPlanFromJson(json);

  Map<String, dynamic> toJson() => _$AdminPlanToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum AdminPlanIntervalEnum {
@JsonValue(r'none')
none(r'none'),
@JsonValue(r'week')
week(r'week'),
@JsonValue(r'month')
month(r'month'),
@JsonValue(r'year')
year(r'year');

const AdminPlanIntervalEnum(this.value);

final String value;

@override
String toString() => value;
}


