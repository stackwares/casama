// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'public_config.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$PublicConfigCWProxy {
  PublicConfig productName(String productName);

  PublicConfig apiVersion(String apiVersion);

  PublicConfig supabaseUrl(String supabaseUrl);

  PublicConfig supabaseAnonKey(String supabaseAnonKey);

  PublicConfig billingEnabled(bool billingEnabled);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PublicConfig(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PublicConfig(...).copyWith(id: 12, name: "My name")
  /// ````
  PublicConfig call({
    String productName,
    String apiVersion,
    String supabaseUrl,
    String supabaseAnonKey,
    bool billingEnabled,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfPublicConfig.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfPublicConfig.copyWith.fieldName(...)`
class _$PublicConfigCWProxyImpl implements _$PublicConfigCWProxy {
  const _$PublicConfigCWProxyImpl(this._value);

  final PublicConfig _value;

  @override
  PublicConfig productName(String productName) =>
      this(productName: productName);

  @override
  PublicConfig apiVersion(String apiVersion) => this(apiVersion: apiVersion);

  @override
  PublicConfig supabaseUrl(String supabaseUrl) =>
      this(supabaseUrl: supabaseUrl);

  @override
  PublicConfig supabaseAnonKey(String supabaseAnonKey) =>
      this(supabaseAnonKey: supabaseAnonKey);

  @override
  PublicConfig billingEnabled(bool billingEnabled) =>
      this(billingEnabled: billingEnabled);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `PublicConfig(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// PublicConfig(...).copyWith(id: 12, name: "My name")
  /// ````
  PublicConfig call({
    Object? productName = const $CopyWithPlaceholder(),
    Object? apiVersion = const $CopyWithPlaceholder(),
    Object? supabaseUrl = const $CopyWithPlaceholder(),
    Object? supabaseAnonKey = const $CopyWithPlaceholder(),
    Object? billingEnabled = const $CopyWithPlaceholder(),
  }) {
    return PublicConfig(
      productName: productName == const $CopyWithPlaceholder()
          ? _value.productName
          // ignore: cast_nullable_to_non_nullable
          : productName as String,
      apiVersion: apiVersion == const $CopyWithPlaceholder()
          ? _value.apiVersion
          // ignore: cast_nullable_to_non_nullable
          : apiVersion as String,
      supabaseUrl: supabaseUrl == const $CopyWithPlaceholder()
          ? _value.supabaseUrl
          // ignore: cast_nullable_to_non_nullable
          : supabaseUrl as String,
      supabaseAnonKey: supabaseAnonKey == const $CopyWithPlaceholder()
          ? _value.supabaseAnonKey
          // ignore: cast_nullable_to_non_nullable
          : supabaseAnonKey as String,
      billingEnabled: billingEnabled == const $CopyWithPlaceholder()
          ? _value.billingEnabled
          // ignore: cast_nullable_to_non_nullable
          : billingEnabled as bool,
    );
  }
}

extension $PublicConfigCopyWith on PublicConfig {
  /// Returns a callable class that can be used as follows: `instanceOfPublicConfig.copyWith(...)` or like so:`instanceOfPublicConfig.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$PublicConfigCWProxy get copyWith => _$PublicConfigCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PublicConfig _$PublicConfigFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'PublicConfig',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'product_name',
            'api_version',
            'supabase_url',
            'supabase_anon_key',
            'billing_enabled',
          ],
        );
        final val = PublicConfig(
          productName: $checkedConvert('product_name', (v) => v as String),
          apiVersion: $checkedConvert('api_version', (v) => v as String),
          supabaseUrl: $checkedConvert('supabase_url', (v) => v as String),
          supabaseAnonKey: $checkedConvert(
            'supabase_anon_key',
            (v) => v as String,
          ),
          billingEnabled: $checkedConvert('billing_enabled', (v) => v as bool),
        );
        return val;
      },
      fieldKeyMap: const {
        'productName': 'product_name',
        'apiVersion': 'api_version',
        'supabaseUrl': 'supabase_url',
        'supabaseAnonKey': 'supabase_anon_key',
        'billingEnabled': 'billing_enabled',
      },
    );

Map<String, dynamic> _$PublicConfigToJson(PublicConfig instance) =>
    <String, dynamic>{
      'product_name': instance.productName,
      'api_version': instance.apiVersion,
      'supabase_url': instance.supabaseUrl,
      'supabase_anon_key': instance.supabaseAnonKey,
      'billing_enabled': instance.billingEnabled,
    };
