//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'save_model_catalog_request.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class SaveModelCatalogRequest {
  /// Returns a new [SaveModelCatalogRequest] instance.
  SaveModelCatalogRequest({

    required  this.catalog,
  });

  @JsonKey(
    
    name: r'catalog',
    required: true,
    includeIfNull: false,
  )


  final Map<String, Object?> catalog;





    @override
    bool operator ==(Object other) => identical(this, other) || other is SaveModelCatalogRequest &&
      other.catalog == catalog;

    @override
    int get hashCode =>
        catalog.hashCode;

  factory SaveModelCatalogRequest.fromJson(Map<String, dynamic> json) => _$SaveModelCatalogRequestFromJson(json);

  Map<String, dynamic> toJson() => _$SaveModelCatalogRequestToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

