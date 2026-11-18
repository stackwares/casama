//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'admin_price_tables.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminPriceTables {
  /// Returns a new [AdminPriceTables] instance.
  AdminPriceTables({

    required  this.costTables,

    required  this.builtIn,

    required  this.domainTlds,

    required  this.domainTldsSaved,

    required  this.domainCapFirstMonth,

    required  this.domainCapPerMonth,
  });

      /// What's saved: voice, gemini_live, computers, media. A price left out uses the one in code.
  @JsonKey(
    
    name: r'cost_tables',
    required: true,
    includeIfNull: false,
  )


  final Map<String, Object?> costTables;



      /// The prices in code, in the same shape
  @JsonKey(
    
    name: r'built_in',
    required: true,
    includeIfNull: false,
  )


  final Map<String, Object?> builtIn;



      /// The endings on sale now (saved, else CASAMA_DOMAINS_TLDS, else code)
  @JsonKey(
    
    name: r'domain_tlds',
    required: true,
    includeIfNull: false,
  )


  final List<String> domainTlds;



      /// Whether domain_tlds is the saved list
  @JsonKey(
    
    name: r'domain_tlds_saved',
    required: true,
    includeIfNull: false,
  )


  final bool domainTldsSaved;



  @JsonKey(
    
    name: r'domain_cap_first_month',
    required: true,
    includeIfNull: false,
  )


  final int domainCapFirstMonth;



  @JsonKey(
    
    name: r'domain_cap_per_month',
    required: true,
    includeIfNull: false,
  )


  final int domainCapPerMonth;





    @override
    bool operator ==(Object other) => identical(this, other) || other is AdminPriceTables &&
      other.costTables == costTables &&
      other.builtIn == builtIn &&
      other.domainTlds == domainTlds &&
      other.domainTldsSaved == domainTldsSaved &&
      other.domainCapFirstMonth == domainCapFirstMonth &&
      other.domainCapPerMonth == domainCapPerMonth;

    @override
    int get hashCode =>
        costTables.hashCode +
        builtIn.hashCode +
        domainTlds.hashCode +
        domainTldsSaved.hashCode +
        domainCapFirstMonth.hashCode +
        domainCapPerMonth.hashCode;

  factory AdminPriceTables.fromJson(Map<String, dynamic> json) => _$AdminPriceTablesFromJson(json);

  Map<String, dynamic> toJson() => _$AdminPriceTablesToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

