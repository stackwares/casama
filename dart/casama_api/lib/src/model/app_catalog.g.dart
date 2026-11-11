// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_catalog.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$AppCatalogCWProxy {
  AppCatalog apps(List<CatalogApp> apps);

  AppCatalog redirectUri(String redirectUri);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `AppCatalog(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// AppCatalog(...).copyWith(id: 12, name: "My name")
  /// ```
  AppCatalog call({List<CatalogApp> apps, String redirectUri});
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

AppCatalog _$AppCatalogFromJson(Map<String, dynamic> json) =>
    $checkedCreate('AppCatalog', json, ($checkedConvert) {
      $checkKeys(json, requiredKeys: const ['apps', 'redirect_uri']);
      final val = AppCatalog(
        apps: $checkedConvert(
          'apps',
          (v) => (v as List<dynamic>)
              .map((e) => CatalogApp.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
        redirectUri: $checkedConvert('redirect_uri', (v) => v as String),
      );
      return val;
    }, fieldKeyMap: const {'redirectUri': 'redirect_uri'});

Map<String, dynamic> _$AppCatalogToJson(AppCatalog instance) =>
    <String, dynamic>{
      'apps': instance.apps.map((e) => e.toJson()).toList(),
      'redirect_uri': instance.redirectUri,
    };
