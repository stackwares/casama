// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sites_config.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SitesConfigCWProxy {
  SitesConfig zone(String? zone);

  SitesConfig customDomains(bool customDomains);

  SitesConfig buyDomains(bool buyDomains);

  SitesConfig tlds(List<String> tlds);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SitesConfig(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SitesConfig(...).copyWith(id: 12, name: "My name")
  /// ```
  SitesConfig call({
    String? zone,
    bool customDomains,
    bool buyDomains,
    List<String> tlds,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfSitesConfig.copyWith(...)` or call `instanceOfSitesConfig.copyWith.fieldName(value)` for a single field.
class _$SitesConfigCWProxyImpl implements _$SitesConfigCWProxy {
  const _$SitesConfigCWProxyImpl(this._value);

  final SitesConfig _value;

  @override
  SitesConfig zone(String? zone) => call(zone: zone);

  @override
  SitesConfig customDomains(bool customDomains) =>
      call(customDomains: customDomains);

  @override
  SitesConfig buyDomains(bool buyDomains) => call(buyDomains: buyDomains);

  @override
  SitesConfig tlds(List<String> tlds) => call(tlds: tlds);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SitesConfig(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SitesConfig(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  SitesConfig call({
    Object? zone = const $CopyWithPlaceholder(),
    Object? customDomains = const $CopyWithPlaceholder(),
    Object? buyDomains = const $CopyWithPlaceholder(),
    Object? tlds = const $CopyWithPlaceholder(),
  }) {
    return SitesConfig(
      zone: zone == const $CopyWithPlaceholder()
          ? _value.zone
          // ignore: cast_nullable_to_non_nullable
          : zone as String?,
      customDomains:
          customDomains == const $CopyWithPlaceholder() || customDomains == null
          ? _value.customDomains
          // ignore: cast_nullable_to_non_nullable
          : customDomains as bool,
      buyDomains:
          buyDomains == const $CopyWithPlaceholder() || buyDomains == null
          ? _value.buyDomains
          // ignore: cast_nullable_to_non_nullable
          : buyDomains as bool,
      tlds: tlds == const $CopyWithPlaceholder() || tlds == null
          ? _value.tlds
          // ignore: cast_nullable_to_non_nullable
          : tlds as List<String>,
    );
  }
}

extension $SitesConfigCopyWith on SitesConfig {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfSitesConfig.copyWith(...)` or `instanceOfSitesConfig.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SitesConfigCWProxy get copyWith => _$SitesConfigCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SitesConfig _$SitesConfigFromJson(Map<String, dynamic> json) => $checkedCreate(
  'SitesConfig',
  json,
  ($checkedConvert) {
    $checkKeys(
      json,
      requiredKeys: const ['zone', 'custom_domains', 'buy_domains', 'tlds'],
    );
    final val = SitesConfig(
      zone: $checkedConvert('zone', (v) => v as String?),
      customDomains: $checkedConvert('custom_domains', (v) => v as bool),
      buyDomains: $checkedConvert('buy_domains', (v) => v as bool),
      tlds: $checkedConvert(
        'tlds',
        (v) => (v as List<dynamic>).map((e) => e as String).toList(),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'customDomains': 'custom_domains',
    'buyDomains': 'buy_domains',
  },
);

Map<String, dynamic> _$SitesConfigToJson(SitesConfig instance) =>
    <String, dynamic>{
      'zone': instance.zone,
      'custom_domains': instance.customDomains,
      'buy_domains': instance.buyDomains,
      'tlds': instance.tlds,
    };
