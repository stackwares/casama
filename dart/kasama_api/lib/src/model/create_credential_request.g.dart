// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_credential_request.dart';

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class _$CreateCredentialRequestCWProxy {
  CreateCredentialRequest orgId(String orgId);

  CreateCredentialRequest provider(ProviderId provider);

  CreateCredentialRequest label(String label);

  CreateCredentialRequest apiKey(String? apiKey);

  CreateCredentialRequest baseUrl(String? baseUrl);

  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `CreateCredentialRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// CreateCredentialRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  CreateCredentialRequest call({
    String orgId,
    ProviderId provider,
    String label,
    String? apiKey,
    String? baseUrl,
  });
}

/// Proxy class for `copyWith` functionality. This is a callable class and can be used as follows: `instanceOfCreateCredentialRequest.copyWith(...)`. Additionally contains functions for specific fields e.g. `instanceOfCreateCredentialRequest.copyWith.fieldName(...)`
class _$CreateCredentialRequestCWProxyImpl
    implements _$CreateCredentialRequestCWProxy {
  const _$CreateCredentialRequestCWProxyImpl(this._value);

  final CreateCredentialRequest _value;

  @override
  CreateCredentialRequest orgId(String orgId) => this(orgId: orgId);

  @override
  CreateCredentialRequest provider(ProviderId provider) =>
      this(provider: provider);

  @override
  CreateCredentialRequest label(String label) => this(label: label);

  @override
  CreateCredentialRequest apiKey(String? apiKey) => this(apiKey: apiKey);

  @override
  CreateCredentialRequest baseUrl(String? baseUrl) => this(baseUrl: baseUrl);

  @override
  /// This function **does support** nullification of nullable fields. All `null` values passed to `non-nullable` fields will be ignored. You can also use `CreateCredentialRequest(...).copyWith.fieldName(...)` to override fields one at a time with nullification support.
  ///
  /// Usage
  /// ```dart
  /// CreateCredentialRequest(...).copyWith(id: 12, name: "My name")
  /// ````
  CreateCredentialRequest call({
    Object? orgId = const $CopyWithPlaceholder(),
    Object? provider = const $CopyWithPlaceholder(),
    Object? label = const $CopyWithPlaceholder(),
    Object? apiKey = const $CopyWithPlaceholder(),
    Object? baseUrl = const $CopyWithPlaceholder(),
  }) {
    return CreateCredentialRequest(
      orgId: orgId == const $CopyWithPlaceholder()
          ? _value.orgId
          // ignore: cast_nullable_to_non_nullable
          : orgId as String,
      provider: provider == const $CopyWithPlaceholder()
          ? _value.provider
          // ignore: cast_nullable_to_non_nullable
          : provider as ProviderId,
      label: label == const $CopyWithPlaceholder()
          ? _value.label
          // ignore: cast_nullable_to_non_nullable
          : label as String,
      apiKey: apiKey == const $CopyWithPlaceholder()
          ? _value.apiKey
          // ignore: cast_nullable_to_non_nullable
          : apiKey as String?,
      baseUrl: baseUrl == const $CopyWithPlaceholder()
          ? _value.baseUrl
          // ignore: cast_nullable_to_non_nullable
          : baseUrl as String?,
    );
  }
}

extension $CreateCredentialRequestCopyWith on CreateCredentialRequest {
  /// Returns a callable class that can be used as follows: `instanceOfCreateCredentialRequest.copyWith(...)` or like so:`instanceOfCreateCredentialRequest.copyWith.fieldName(...)`.
  // ignore: library_private_types_in_public_api
  _$CreateCredentialRequestCWProxy get copyWith =>
      _$CreateCredentialRequestCWProxyImpl(this);
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateCredentialRequest _$CreateCredentialRequestFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'CreateCredentialRequest',
  json,
  ($checkedConvert) {
    $checkKeys(json, requiredKeys: const ['org_id', 'provider', 'label']);
    final val = CreateCredentialRequest(
      orgId: $checkedConvert('org_id', (v) => v as String),
      provider: $checkedConvert(
        'provider',
        (v) => $enumDecode(_$ProviderIdEnumMap, v),
      ),
      label: $checkedConvert('label', (v) => v as String),
      apiKey: $checkedConvert('api_key', (v) => v as String?),
      baseUrl: $checkedConvert('base_url', (v) => v as String?),
    );
    return val;
  },
  fieldKeyMap: const {
    'orgId': 'org_id',
    'apiKey': 'api_key',
    'baseUrl': 'base_url',
  },
);

Map<String, dynamic> _$CreateCredentialRequestToJson(
  CreateCredentialRequest instance,
) => <String, dynamic>{
  'org_id': instance.orgId,
  'provider': _$ProviderIdEnumMap[instance.provider]!,
  'label': instance.label,
  'api_key': ?instance.apiKey,
  'base_url': ?instance.baseUrl,
};

const _$ProviderIdEnumMap = {
  ProviderId.openai: 'openai',
  ProviderId.anthropic: 'anthropic',
  ProviderId.google: 'google',
  ProviderId.xai: 'xai',
  ProviderId.openrouter: 'openrouter',
  ProviderId.openaiCompatible: 'openai_compatible',
};
