// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'secret_store_settings.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$SecretStoreSettingsCWProxy {
  SecretStoreSettings provider(SecretStoreSettingsProviderEnum provider);

  SecretStoreSettings siteUrl(String? siteUrl);

  SecretStoreSettings projectId(String? projectId);

  SecretStoreSettings environment(String? environment);

  SecretStoreSettings secretPath(String? secretPath);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SecretStoreSettings(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SecretStoreSettings(...).copyWith(id: 12, name: "My name")
  /// ```
  SecretStoreSettings call({
    SecretStoreSettingsProviderEnum provider,
    String? siteUrl,
    String? projectId,
    String? environment,
    String? secretPath,
  });
}

/// Callable proxy for `copyWith` functionality.
/// Use as `instanceOfSecretStoreSettings.copyWith(...)` or call `instanceOfSecretStoreSettings.copyWith.fieldName(value)` for a single field.
class _$SecretStoreSettingsCWProxyImpl implements _$SecretStoreSettingsCWProxy {
  const _$SecretStoreSettingsCWProxyImpl(this._value);

  final SecretStoreSettings _value;

  @override
  SecretStoreSettings provider(SecretStoreSettingsProviderEnum provider) =>
      call(provider: provider);

  @override
  SecretStoreSettings siteUrl(String? siteUrl) => call(siteUrl: siteUrl);

  @override
  SecretStoreSettings projectId(String? projectId) =>
      call(projectId: projectId);

  @override
  SecretStoreSettings environment(String? environment) =>
      call(environment: environment);

  @override
  SecretStoreSettings secretPath(String? secretPath) =>
      call(secretPath: secretPath);

  /// Creates a new instance with the provided field values.
  /// Omitted fields keep their values; explicit `null` clears nullable fields.
  /// The public API rejects `null` for non-nullable fields. To update a single field use `SecretStoreSettings(...).copyWith.fieldName(value)`.
  ///
  /// Example:
  /// ```dart
  /// SecretStoreSettings(...).copyWith(id: 12, name: "My name")
  /// ```
  @override
  SecretStoreSettings call({
    Object? provider = const $CopyWithPlaceholder(),
    Object? siteUrl = const $CopyWithPlaceholder(),
    Object? projectId = const $CopyWithPlaceholder(),
    Object? environment = const $CopyWithPlaceholder(),
    Object? secretPath = const $CopyWithPlaceholder(),
  }) {
    return SecretStoreSettings(
      provider: provider == const $CopyWithPlaceholder() || provider == null
          ? _value.provider
          // ignore: cast_nullable_to_non_nullable
          : provider as SecretStoreSettingsProviderEnum,
      siteUrl: siteUrl == const $CopyWithPlaceholder()
          ? _value.siteUrl
          // ignore: cast_nullable_to_non_nullable
          : siteUrl as String?,
      projectId: projectId == const $CopyWithPlaceholder()
          ? _value.projectId
          // ignore: cast_nullable_to_non_nullable
          : projectId as String?,
      environment: environment == const $CopyWithPlaceholder()
          ? _value.environment
          // ignore: cast_nullable_to_non_nullable
          : environment as String?,
      secretPath: secretPath == const $CopyWithPlaceholder()
          ? _value.secretPath
          // ignore: cast_nullable_to_non_nullable
          : secretPath as String?,
    );
  }
}

extension $SecretStoreSettingsCopyWith on SecretStoreSettings {
  /// Returns a callable class used to build a new instance with modified fields.
  /// Example: `instanceOfSecretStoreSettings.copyWith(...)` or `instanceOfSecretStoreSettings.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$SecretStoreSettingsCWProxy get copyWith =>
      _$SecretStoreSettingsCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SecretStoreSettings _$SecretStoreSettingsFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'SecretStoreSettings',
      json,
      ($checkedConvert) {
        $checkKeys(
          json,
          requiredKeys: const [
            'provider',
            'site_url',
            'project_id',
            'environment',
            'secret_path',
          ],
        );
        final val = SecretStoreSettings(
          provider: $checkedConvert(
            'provider',
            (v) => $enumDecode(_$SecretStoreSettingsProviderEnumEnumMap, v),
          ),
          siteUrl: $checkedConvert('site_url', (v) => v as String?),
          projectId: $checkedConvert('project_id', (v) => v as String?),
          environment: $checkedConvert('environment', (v) => v as String?),
          secretPath: $checkedConvert('secret_path', (v) => v as String?),
        );
        return val;
      },
      fieldKeyMap: const {
        'siteUrl': 'site_url',
        'projectId': 'project_id',
        'secretPath': 'secret_path',
      },
    );

Map<String, dynamic> _$SecretStoreSettingsToJson(
  SecretStoreSettings instance,
) => <String, dynamic>{
  'provider': _$SecretStoreSettingsProviderEnumEnumMap[instance.provider]!,
  'site_url': instance.siteUrl,
  'project_id': instance.projectId,
  'environment': instance.environment,
  'secret_path': instance.secretPath,
};

const _$SecretStoreSettingsProviderEnumEnumMap = {
  SecretStoreSettingsProviderEnum.vault: 'vault',
  SecretStoreSettingsProviderEnum.infisical: 'infisical',
};
