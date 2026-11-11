//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'provider_app.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class ProviderApp {
  /// Returns a new [ProviderApp] instance.
  ProviderApp({

    required  this.slug,

    required  this.name,

    required  this.description,

    required  this.logo,
  });

  @JsonKey(
    
    name: r'slug',
    required: true,
    includeIfNull: false,
  )


  final String slug;



  @JsonKey(
    
    name: r'name',
    required: true,
    includeIfNull: false,
  )


  final String name;



  @JsonKey(
    
    name: r'description',
    required: true,
    includeIfNull: false,
  )


  final String description;



  @JsonKey(
    
    name: r'logo',
    required: true,
    includeIfNull: true,
  )


  final String? logo;





    @override
    bool operator ==(Object other) => identical(this, other) || other is ProviderApp &&
      other.slug == slug &&
      other.name == name &&
      other.description == description &&
      other.logo == logo;

    @override
    int get hashCode =>
        slug.hashCode +
        name.hashCode +
        description.hashCode +
        (logo == null ? 0 : logo.hashCode);

  factory ProviderApp.fromJson(Map<String, dynamic> json) => _$ProviderAppFromJson(json);

  Map<String, dynamic> toJson() => _$ProviderAppToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

