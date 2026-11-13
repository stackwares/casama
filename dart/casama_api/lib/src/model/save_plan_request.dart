//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'save_plan_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SavePlanRequest {
  /// Returns a new [SavePlanRequest] instance.
  SavePlanRequest({

     this.name,

     this.interval,

     this.active,

     this.sort,

     this.priceLabel,

     this.limits,

     this.creditGate,

     this.storeProductIds,

     this.dodoProductId,
  });

  @JsonKey(
    
    name: r'name',
    required: false,
    includeIfNull: false,
  )


  final String? name;



  @JsonKey(
    
    name: r'interval',
    required: false,
    includeIfNull: false,
  )


  final SavePlanRequestIntervalEnum? interval;



  @JsonKey(
    
    name: r'active',
    required: false,
    includeIfNull: false,
  )


  final bool? active;



  @JsonKey(
    
    name: r'sort',
    required: false,
    includeIfNull: false,
  )


  final int? sort;



  @JsonKey(
    
    name: r'price_label',
    required: false,
    includeIfNull: false,
  )


  final String? priceLabel;



      /// Replaces the plan's limits; every workspace on the plan gets them right away
  @JsonKey(
    
    name: r'limits',
    required: false,
    includeIfNull: false,
  )


  final Map<String, num>? limits;



  @JsonKey(
    
    name: r'credit_gate',
    required: false,
    includeIfNull: false,
  )


  final bool? creditGate;



  @JsonKey(
    
    name: r'store_product_ids',
    required: false,
    includeIfNull: false,
  )


  final Map<String, String>? storeProductIds;



  @JsonKey(
    
    name: r'dodo_product_id',
    required: false,
    includeIfNull: false,
  )


  final String? dodoProductId;





    @override
    bool operator ==(Object other) => identical(this, other) || other is SavePlanRequest &&
      other.name == name &&
      other.interval == interval &&
      other.active == active &&
      other.sort == sort &&
      other.priceLabel == priceLabel &&
      other.limits == limits &&
      other.creditGate == creditGate &&
      other.storeProductIds == storeProductIds &&
      other.dodoProductId == dodoProductId;

    @override
    int get hashCode =>
        name.hashCode +
        interval.hashCode +
        active.hashCode +
        sort.hashCode +
        (priceLabel == null ? 0 : priceLabel.hashCode) +
        limits.hashCode +
        creditGate.hashCode +
        storeProductIds.hashCode +
        (dodoProductId == null ? 0 : dodoProductId.hashCode);

  factory SavePlanRequest.fromJson(Map<String, dynamic> json) => _$SavePlanRequestFromJson(json);

  Map<String, dynamic> toJson() => _$SavePlanRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum SavePlanRequestIntervalEnum {
@JsonValue(r'none')
none(r'none'),
@JsonValue(r'month')
month(r'month'),
@JsonValue(r'year')
year(r'year');

const SavePlanRequestIntervalEnum(this.value);

final String value;

@override
String toString() => value;
}


