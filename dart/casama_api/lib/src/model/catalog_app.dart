//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:casama_api/src/model/catalog_app_api_key.dart';
import 'package:casama_api/src/model/gallery_access.dart';
import 'package:casama_api/src/model/gallery_stats.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';

part 'catalog_app.g.dart';


@CopyWith()
@JsonSerializable(
  checked: true,
  createToJson: true,
  disallowUnrecognizedKeys: false,
  explicitToJson: true,
)
class CatalogApp {
  /// Returns a new [CatalogApp] instance.
  CatalogApp({

    required  this.id,

    required  this.name,

    required  this.description,

    required  this.category,

    required  this.color,

    required  this.homepage,

    required  this.url,

    required  this.auth,

     this.apiKey,

    required  this.capabilities,

    required  this.popular,

     this.note,

    required  this.oauthAvailable,

     this.composio,

     this.logoUrl,

     this.added,

     this.pick,

     this.examples,

     this.access,

     this.minApp,

     this.source_,

     this.version,

     this.stats,
  });

  @JsonKey(
    
    name: r'id',
    required: true,
    includeIfNull: false,
  )


  final String id;



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
    
    name: r'category',
    required: true,
    includeIfNull: false,
  )


  final CatalogAppCategoryEnum category;



      /// Brand color, hex without #
  @JsonKey(
    
    name: r'color',
    required: true,
    includeIfNull: false,
  )


  final String color;



  @JsonKey(
    
    name: r'homepage',
    required: true,
    includeIfNull: false,
  )


  final String homepage;



  @JsonKey(
    
    name: r'url',
    required: true,
    includeIfNull: false,
  )


  final String url;



  @JsonKey(
    
    name: r'auth',
    required: true,
    includeIfNull: false,
  )


  final List<CatalogAppAuthEnum> auth;



  @JsonKey(
    
    name: r'api_key',
    required: false,
    includeIfNull: false,
  )


  final CatalogAppApiKey? apiKey;



  @JsonKey(
    
    name: r'capabilities',
    required: true,
    includeIfNull: false,
  )


  final List<String> capabilities;



  @JsonKey(
    
    name: r'popular',
    required: true,
    includeIfNull: false,
  )


  final bool popular;



  @JsonKey(
    
    name: r'note',
    required: false,
    includeIfNull: false,
  )


  final String? note;



  @JsonKey(
    
    name: r'oauth_available',
    required: true,
    includeIfNull: false,
  )


  final bool oauthAvailable;



  @JsonKey(
    
    name: r'composio',
    required: false,
    includeIfNull: false,
  )


  final String? composio;



  @JsonKey(
    
    name: r'logo_url',
    required: false,
    includeIfNull: false,
  )


  final String? logoUrl;



      /// YYYY-MM-DD the item was added
  @JsonKey(
    
    name: r'added',
    required: false,
    includeIfNull: false,
  )


  final String? added;



      /// Why a featured item is a pick
  @JsonKey(
    
    name: r'pick',
    required: false,
    includeIfNull: false,
  )


  final String? pick;



  @JsonKey(
    
    name: r'examples',
    required: false,
    includeIfNull: false,
  )


  final List<String>? examples;



  @JsonKey(
    
    name: r'access',
    required: false,
    includeIfNull: false,
  )


  final GalleryAccess? access;



  @JsonKey(
    
    name: r'min_app',
    required: false,
    includeIfNull: false,
  )


  final String? minApp;



      /// The extra catalog it came from (GALLERY_SOURCES); ids are source:id
  @JsonKey(
    
    name: r'source',
    required: false,
    includeIfNull: false,
  )


  final String? source_;



  @JsonKey(
    
    name: r'version',
    required: false,
    includeIfNull: false,
  )


  final int? version;



  @JsonKey(
    
    name: r'stats',
    required: false,
    includeIfNull: false,
  )


  final GalleryStats? stats;





    @override
    bool operator ==(Object other) => identical(this, other) || other is CatalogApp &&
      other.id == id &&
      other.name == name &&
      other.description == description &&
      other.category == category &&
      other.color == color &&
      other.homepage == homepage &&
      other.url == url &&
      other.auth == auth &&
      other.apiKey == apiKey &&
      other.capabilities == capabilities &&
      other.popular == popular &&
      other.note == note &&
      other.oauthAvailable == oauthAvailable &&
      other.composio == composio &&
      other.logoUrl == logoUrl &&
      other.added == added &&
      other.pick == pick &&
      other.examples == examples &&
      other.access == access &&
      other.minApp == minApp &&
      other.source_ == source_ &&
      other.version == version &&
      other.stats == stats;

    @override
    int get hashCode =>
        id.hashCode +
        name.hashCode +
        description.hashCode +
        category.hashCode +
        color.hashCode +
        homepage.hashCode +
        url.hashCode +
        auth.hashCode +
        apiKey.hashCode +
        capabilities.hashCode +
        popular.hashCode +
        note.hashCode +
        oauthAvailable.hashCode +
        composio.hashCode +
        logoUrl.hashCode +
        added.hashCode +
        pick.hashCode +
        examples.hashCode +
        access.hashCode +
        minApp.hashCode +
        source_.hashCode +
        version.hashCode +
        stats.hashCode;

  factory CatalogApp.fromJson(Map<String, dynamic> json) => _$CatalogAppFromJson(json);

  Map<String, dynamic> toJson() => _$CatalogAppToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}


enum CatalogAppCategoryEnum {
@JsonValue(r'developer')
developer(r'developer'),
@JsonValue(r'productivity')
productivity(r'productivity'),
@JsonValue(r'google')
google(r'google'),
@JsonValue(r'payments')
payments(r'payments'),
@JsonValue(r'design')
design(r'design'),
@JsonValue(r'sales')
sales(r'sales'),
@JsonValue(r'data')
data(r'data'),
@JsonValue(r'automation')
automation(r'automation');

const CatalogAppCategoryEnum(this.value);

final String value;

@override
String toString() => value;
}



enum CatalogAppAuthEnum {
@JsonValue(r'oauth')
oauth(r'oauth'),
@JsonValue(r'api_key')
apiKey(r'api_key'),
@JsonValue(r'none')
none(r'none'),
@JsonValue(r'managed')
managed(r'managed');

const CatalogAppAuthEnum(this.value);

final String value;

@override
String toString() => value;
}


