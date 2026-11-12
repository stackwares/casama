// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'catalog_app.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CatalogAppCWProxy {
  CatalogApp id(String id);

  CatalogApp name(String name);

  CatalogApp description(String description);

  CatalogApp category(CatalogAppCategoryEnum category);

  CatalogApp color(String color);

  CatalogApp homepage(String homepage);

  CatalogApp url(String url);

  CatalogApp auth(List<CatalogAppAuthEnum> auth);

  CatalogApp apiKey(CatalogAppApiKey? apiKey);

  CatalogApp capabilities(List<String> capabilities);

  CatalogApp popular(bool popular);

  CatalogApp note(String? note);

  CatalogApp oauthAvailable(bool oauthAvailable);

  CatalogApp composio(String? composio);

  CatalogApp logoUrl(String? logoUrl);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CatalogApp(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CatalogApp(...).copyWith(id: 12, name: "My name")
  /// ```
  CatalogApp call({
    String id,
    String name,
    String description,
    CatalogAppCategoryEnum category,
    String color,
    String homepage,
    String url,
    List<CatalogAppAuthEnum> auth,
    CatalogAppApiKey? apiKey,
    List<String> capabilities,
    bool popular,
    String? note,
    bool oauthAvailable,
    String? composio,
    String? logoUrl,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfCatalogApp.copyWith(...)` or call `instanceOfCatalogApp.copyWith.fieldName(value)` for a single field.
class _$CatalogAppCWProxyImpl implements _$CatalogAppCWProxy {
  const _$CatalogAppCWProxyImpl(this._value);

  final CatalogApp _value;

  @override
  CatalogApp id(String id) => call(id: id);

  @override
  CatalogApp name(String name) => call(name: name);

  @override
  CatalogApp description(String description) => call(description: description);

  @override
  CatalogApp category(CatalogAppCategoryEnum category) =>
      call(category: category);

  @override
  CatalogApp color(String color) => call(color: color);

  @override
  CatalogApp homepage(String homepage) => call(homepage: homepage);

  @override
  CatalogApp url(String url) => call(url: url);

  @override
  CatalogApp auth(List<CatalogAppAuthEnum> auth) => call(auth: auth);

  @override
  CatalogApp apiKey(CatalogAppApiKey? apiKey) => call(apiKey: apiKey);

  @override
  CatalogApp capabilities(List<String> capabilities) =>
      call(capabilities: capabilities);

  @override
  CatalogApp popular(bool popular) => call(popular: popular);

  @override
  CatalogApp note(String? note) => call(note: note);

  @override
  CatalogApp oauthAvailable(bool oauthAvailable) =>
      call(oauthAvailable: oauthAvailable);

  @override
  CatalogApp composio(String? composio) => call(composio: composio);

  @override
  CatalogApp logoUrl(String? logoUrl) => call(logoUrl: logoUrl);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `CatalogApp(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// CatalogApp(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  CatalogApp call({
    Object? id = const $CopyWithPlaceholder(),
    Object? name = const $CopyWithPlaceholder(),
    Object? description = const $CopyWithPlaceholder(),
    Object? category = const $CopyWithPlaceholder(),
    Object? color = const $CopyWithPlaceholder(),
    Object? homepage = const $CopyWithPlaceholder(),
    Object? url = const $CopyWithPlaceholder(),
    Object? auth = const $CopyWithPlaceholder(),
    Object? apiKey = const $CopyWithPlaceholder(),
    Object? capabilities = const $CopyWithPlaceholder(),
    Object? popular = const $CopyWithPlaceholder(),
    Object? note = const $CopyWithPlaceholder(),
    Object? oauthAvailable = const $CopyWithPlaceholder(),
    Object? composio = const $CopyWithPlaceholder(),
    Object? logoUrl = const $CopyWithPlaceholder(),
  }) {
    return CatalogApp(
      id: id == const $CopyWithPlaceholder() || id == null
          ? _value.id
          // ignore: cast_nullable_to_non_nullable
          : id as String,
      name: name == const $CopyWithPlaceholder() || name == null
          ? _value.name
          // ignore: cast_nullable_to_non_nullable
          : name as String,
      description:
          description == const $CopyWithPlaceholder() || description == null
          ? _value.description
          // ignore: cast_nullable_to_non_nullable
          : description as String,
      category: category == const $CopyWithPlaceholder() || category == null
          ? _value.category
          // ignore: cast_nullable_to_non_nullable
          : category as CatalogAppCategoryEnum,
      color: color == const $CopyWithPlaceholder() || color == null
          ? _value.color
          // ignore: cast_nullable_to_non_nullable
          : color as String,
      homepage: homepage == const $CopyWithPlaceholder() || homepage == null
          ? _value.homepage
          // ignore: cast_nullable_to_non_nullable
          : homepage as String,
      url: url == const $CopyWithPlaceholder() || url == null
          ? _value.url
          // ignore: cast_nullable_to_non_nullable
          : url as String,
      auth: auth == const $CopyWithPlaceholder() || auth == null
          ? _value.auth
          // ignore: cast_nullable_to_non_nullable
          : auth as List<CatalogAppAuthEnum>,
      apiKey: apiKey == const $CopyWithPlaceholder()
          ? _value.apiKey
          // ignore: cast_nullable_to_non_nullable
          : apiKey as CatalogAppApiKey?,
      capabilities:
          capabilities == const $CopyWithPlaceholder() || capabilities == null
          ? _value.capabilities
          // ignore: cast_nullable_to_non_nullable
          : capabilities as List<String>,
      popular: popular == const $CopyWithPlaceholder() || popular == null
          ? _value.popular
          // ignore: cast_nullable_to_non_nullable
          : popular as bool,
      note: note == const $CopyWithPlaceholder()
          ? _value.note
          // ignore: cast_nullable_to_non_nullable
          : note as String?,
      oauthAvailable:
          oauthAvailable == const $CopyWithPlaceholder() ||
              oauthAvailable == null
          ? _value.oauthAvailable
          // ignore: cast_nullable_to_non_nullable
          : oauthAvailable as bool,
      composio: composio == const $CopyWithPlaceholder()
          ? _value.composio
          // ignore: cast_nullable_to_non_nullable
          : composio as String?,
      logoUrl: logoUrl == const $CopyWithPlaceholder()
          ? _value.logoUrl
          // ignore: cast_nullable_to_non_nullable
          : logoUrl as String?,
    );
  }
}

extension $CatalogAppCopyWith on CatalogApp {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfCatalogApp.copyWith(...)` or `instanceOfCatalogApp.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CatalogAppCWProxy get copyWith => _$CatalogAppCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CatalogApp _$CatalogAppFromJson(Map<String, dynamic> json) => $checkedCreate(
  'CatalogApp',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const [
        'id',
        'name',
        'description',
        'category',
        'color',
        'homepage',
        'url',
        'auth',
        'capabilities',
        'popular',
        'oauth_available',
      ],
    );
    final val = CatalogApp(
      id: $checkedConvert('id', (v) => v as String),
      name: $checkedConvert('name', (v) => v as String),
      description: $checkedConvert('description', (v) => v as String),
      category: $checkedConvert(
        'category',
        (v) => $enumDecode(_$CatalogAppCategoryEnumEnumMap, v),
      ),
      color: $checkedConvert('color', (v) => v as String),
      homepage: $checkedConvert('homepage', (v) => v as String),
      url: $checkedConvert('url', (v) => v as String),
      auth: $checkedConvert(
        'auth',
        (v) => (v as List<dynamic>)
            .map((e) => $enumDecode(_$CatalogAppAuthEnumEnumMap, e))
            .toList(),
      ),
      apiKey: $checkedConvert(
        'api_key',
        (v) => v == null
            ? null
            : CatalogAppApiKey.fromJson(v as Map<String, dynamic>),
      ),
      capabilities: $checkedConvert(
        'capabilities',
        (v) => (v as List<dynamic>).map((e) => e as String).toList(),
      ),
      popular: $checkedConvert('popular', (v) => v as bool),
      note: $checkedConvert('note', (v) => v as String?),
      oauthAvailable: $checkedConvert('oauth_available', (v) => v as bool),
      composio: $checkedConvert('composio', (v) => v as String?),
      logoUrl: $checkedConvert('logo_url', (v) => v as String?),
    );
    return val;
  },
  fieldKeyMap: const {
    'apiKey': 'api_key',
    'oauthAvailable': 'oauth_available',
    'logoUrl': 'logo_url',
  },
);

Map<String, dynamic> _$CatalogAppToJson(
  CatalogApp instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'description': instance.description,
  'category': _$CatalogAppCategoryEnumEnumMap[instance.category]!,
  'color': instance.color,
  'homepage': instance.homepage,
  'url': instance.url,
  'auth': instance.auth.map((e) => _$CatalogAppAuthEnumEnumMap[e]!).toList(),
  'api_key': ?instance.apiKey?.toJson(),
  'capabilities': instance.capabilities,
  'popular': instance.popular,
  'note': ?instance.note,
  'oauth_available': instance.oauthAvailable,
  'composio': ?instance.composio,
  'logo_url': ?instance.logoUrl,
};

const _$CatalogAppCategoryEnumEnumMap = {
  CatalogAppCategoryEnum.developer: 'developer',
  CatalogAppCategoryEnum.productivity: 'productivity',
  CatalogAppCategoryEnum.google: 'google',
  CatalogAppCategoryEnum.payments: 'payments',
  CatalogAppCategoryEnum.design: 'design',
  CatalogAppCategoryEnum.sales: 'sales',
  CatalogAppCategoryEnum.data: 'data',
  CatalogAppCategoryEnum.automation: 'automation',
};

const _$CatalogAppAuthEnumEnumMap = {
  CatalogAppAuthEnum.oauth: 'oauth',
  CatalogAppAuthEnum.apiKey: 'api_key',
  CatalogAppAuthEnum.none: 'none',
  CatalogAppAuthEnum.managed: 'managed',
};
