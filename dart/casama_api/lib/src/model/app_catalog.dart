//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/catalog_app.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'app_catalog.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class AppCatalog {
  /// Returns a new [AppCatalog] instance.
  AppCatalog({

    required  this.apps,

    required  this.redirectUri,

     this.starterApps,
  });

  @JsonKey(
    
    name: r'apps',
    required: true,
    includeIfNull: false,
  )


  final List<CatalogApp> apps;



  @JsonKey(
    
    name: r'redirect_uri',
    required: true,
    includeIfNull: false,
  )


  final String redirectUri;



  @JsonKey(
    
    name: r'starter_apps',
    required: false,
    includeIfNull: false,
  )


  final List<String>? starterApps;





    @override
    bool operator ==(Object other) => identical(this, other) || other is AppCatalog &&
      other.apps == apps &&
      other.redirectUri == redirectUri &&
      other.starterApps == starterApps;

    @override
    int get hashCode =>
        apps.hashCode +
        redirectUri.hashCode +
        starterApps.hashCode;

  factory AppCatalog.fromJson(Map<String, dynamic> json) => _$AppCatalogFromJson(json);

  Map<String, dynamic> toJson() => _$AppCatalogToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

