//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:kasama_api/src/model/plan.dart';
import 'package:kasama_api/src/model/credit_pack.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'plan_catalog.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class PlanCatalog {
  /// Returns a new [PlanCatalog] instance.
  PlanCatalog({

    required  this.enabled,

    required  this.plans,

    required  this.packs,
  });

  @JsonKey(
    
    name: r'enabled',
    required: true,
    includeIfNull: false,
  )


  final bool enabled;



  @JsonKey(
    
    name: r'plans',
    required: true,
    includeIfNull: false,
  )


  final List<Plan> plans;



  @JsonKey(
    
    name: r'packs',
    required: true,
    includeIfNull: false,
  )


  final List<CreditPack> packs;





    @override
    bool operator ==(Object other) => identical(this, other) || other is PlanCatalog &&
      other.enabled == enabled &&
      other.plans == plans &&
      other.packs == packs;

    @override
    int get hashCode =>
        enabled.hashCode +
        plans.hashCode +
        packs.hashCode;

  factory PlanCatalog.fromJson(Map<String, dynamic> json) => _$PlanCatalogFromJson(json);

  Map<String, dynamic> toJson() => _$PlanCatalogToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

