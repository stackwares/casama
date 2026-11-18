//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'save_price_tables_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SavePriceTablesRequest {
  /// Returns a new [SavePriceTablesRequest] instance.
  SavePriceTablesRequest({

     this.costTables,

     this.domainTlds,

     this.domainCapFirstMonth,

     this.domainCapPerMonth,
  });

  @JsonKey(
    
    name: r'cost_tables',
    required: false,
    includeIfNull: false,
  )


  final Map<String, Object?>? costTables;



      /// null goes back to CASAMA_DOMAINS_TLDS or the list in code
  @JsonKey(
    
    name: r'domain_tlds',
    required: false,
    includeIfNull: false,
  )


  final List<String>? domainTlds;



          // minimum: 0
          // maximum: 1000
  @JsonKey(
    
    name: r'domain_cap_first_month',
    required: false,
    includeIfNull: false,
  )


  final int? domainCapFirstMonth;



          // minimum: 0
          // maximum: 1000
  @JsonKey(
    
    name: r'domain_cap_per_month',
    required: false,
    includeIfNull: false,
  )


  final int? domainCapPerMonth;





    @override
    bool operator ==(Object other) => identical(this, other) || other is SavePriceTablesRequest &&
      other.costTables == costTables &&
      other.domainTlds == domainTlds &&
      other.domainCapFirstMonth == domainCapFirstMonth &&
      other.domainCapPerMonth == domainCapPerMonth;

    @override
    int get hashCode =>
        costTables.hashCode +
        (domainTlds == null ? 0 : domainTlds.hashCode) +
        domainCapFirstMonth.hashCode +
        domainCapPerMonth.hashCode;

  factory SavePriceTablesRequest.fromJson(Map<String, dynamic> json) => _$SavePriceTablesRequestFromJson(json);

  Map<String, dynamic> toJson() => _$SavePriceTablesRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

