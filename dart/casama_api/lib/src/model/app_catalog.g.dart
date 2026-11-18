// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_catalog.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AppCatalogCWProxy {
  AppCatalog apps(List<CatalogApp> apps);

  AppCatalog redirectUri(String redirectUri);

  AppCatalog starterApps(List<String>? starterApps);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AppCatalog(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AppCatalog(...).copyWith(id: 12, name: "My name")
  /// ```
  AppCatalog call({
    List<CatalogApp> apps,
    String redirectUri,
    List<String>? starterApps,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfAppCatalog.copyWith(...)` or call `instanceOfAppCatalog.copyWith.fieldName(value)` for a single field.
class _$AppCatalogCWProxyImpl implements _$AppCatalogCWProxy {
  const _$AppCatalogCWProxyImpl(this._value);

  final AppCatalog _value;

  @override
  AppCatalog apps(List<CatalogApp> apps) => call(apps: apps);

  @override
  AppCatalog redirectUri(String redirectUri) => call(redirectUri: redirectUri);

  @override
  AppCatalog starterApps(List<String>? starterApps) =>
      call(starterApps: starterApps);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AppCatalog(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AppCatalog(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  AppCatalog call({
    Object? apps = const $CopyWithPlaceholder(),
    Object? redirectUri = const $CopyWithPlaceholder(),
    Object? starterApps = const $CopyWithPlaceholder(),
  }) {
    return AppCatalog(
      apps: apps == const $CopyWithPlaceholder() || apps == null
          ? _value.apps
          // ignore: cast_nullable_to_non_nullable
          : apps as List<CatalogApp>,
      redirectUri:
          redirectUri == const $CopyWithPlaceholder() || redirectUri == null
          ? _value.redirectUri
          // ignore: cast_nullable_to_non_nullable
          : redirectUri as String,
      starterApps: starterApps == const $CopyWithPlaceholder()
          ? _value.starterApps
          // ignore: cast_nullable_to_non_nullable
          : starterApps as List<String>?,
    );
  }
}

extension $AppCatalogCopyWith on AppCatalog {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfAppCatalog.copyWith(...)` or `instanceOfAppCatalog.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$AppCatalogCWProxy get copyWith => _$AppCatalogCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppCatalog _$AppCatalogFromJson(Map<String, dynamic> json) => $checkedCreate(
  'AppCatalog',
  json,
  ($checkedConvert) {
    $checkKeys(json, requiredKeys: const ['apps', 'redirect_uri']);
    final val = AppCatalog(
      apps: $checkedConvert(
        'apps',
        (v) => (v as List<dynamic>)
            .map((e) => CatalogApp.fromJson(e as Map<String, dynamic>))
            .toList(),
      ),
      redirectUri: $checkedConvert('redirect_uri', (v) => v as String),
      starterApps: $checkedConvert(
        'starter_apps',
        (v) => (v as List<dynamic>?)?.map((e) => e as String).toList(),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'redirectUri': 'redirect_uri',
    'starterApps': 'starter_apps',
  },
);

Map<String, dynamic> _$AppCatalogToJson(AppCatalog instance) =>
    <String, dynamic>{
      'apps': instance.apps.map((e) => e.toJson()).toList(),
      'redirect_uri': instance.redirectUri,
      'starter_apps': ?instance.starterApps,
    };
