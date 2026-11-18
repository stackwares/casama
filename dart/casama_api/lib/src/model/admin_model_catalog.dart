//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'admin_model_catalog.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AdminModelCatalog {
  /// Returns a new [AdminModelCatalog] instance.
  AdminModelCatalog({

    required  this.catalog,

    required  this.builtIn,
  });

      /// What's saved: default_models, small_models, test_models, featured_models, models (price rows), image_prices. Anything left out uses the value in code; {} is all code.
  @JsonKey(
    
    name: r'catalog',
    required: true,
    includeIfNull: false,
  )


  final Map<String, Object?> catalog;



      /// The values in code, in the same shape
  @JsonKey(
    
    name: r'built_in',
    required: true,
    includeIfNull: false,
  )


  final Map<String, Object?> builtIn;





    @override
    bool operator ==(Object other) => identical(this, other) || other is AdminModelCatalog &&
      other.catalog == catalog &&
      other.builtIn == builtIn;

    @override
    int get hashCode =>
        catalog.hashCode +
        builtIn.hashCode;

  factory AdminModelCatalog.fromJson(Map<String, dynamic> json) => _$AdminModelCatalogFromJson(json);

  Map<String, dynamic> toJson() => _$AdminModelCatalogToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

