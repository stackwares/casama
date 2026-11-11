//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'catalog_app_api_key.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CatalogAppApiKey {
  /// Returns a new [CatalogAppApiKey] instance.
  CatalogAppApiKey({

    required  this.label,

     this.placeholder,

    required  this.url,

    required  this.steps,
  });

  @JsonKey(
    
    name: r'label',
    required: true,
    includeIfNull: false,
  )


  final String label;



  @JsonKey(
    
    name: r'placeholder',
    required: false,
    includeIfNull: false,
  )


  final String? placeholder;



  @JsonKey(
    
    name: r'url',
    required: true,
    includeIfNull: false,
  )


  final String url;



  @JsonKey(
    
    name: r'steps',
    required: true,
    includeIfNull: false,
  )


  final List<String> steps;





    @override
    bool operator ==(Object other) => identical(this, other) || other is CatalogAppApiKey &&
      other.label == label &&
      other.placeholder == placeholder &&
      other.url == url &&
      other.steps == steps;

    @override
    int get hashCode =>
        label.hashCode +
        placeholder.hashCode +
        url.hashCode +
        steps.hashCode;

  factory CatalogAppApiKey.fromJson(Map<String, dynamic> json) => _$CatalogAppApiKeyFromJson(json);

  Map<String, dynamic> toJson() => _$CatalogAppApiKeyToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

